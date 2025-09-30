import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

export class DomainAustinFoodClubStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Domain configuration
    const domainName = 'austinfoodclub.com';
    const apiSubdomain = 'api.austinfoodclub.com';

    // Create hosted zone for the domain
    const hostedZone = new route53.HostedZone(this, 'AustinFoodClubHostedZone', {
      zoneName: domainName,
      comment: `Hosted zone for ${domainName}`,
    });

    // Create SSL certificate for the domain and subdomains
    const certificate = new acm.Certificate(this, 'AustinFoodClubCertificate', {
      domainName: domainName,
      subjectAlternativeNames: [apiSubdomain],
      validation: acm.CertificateValidation.fromDns(hostedZone),
    });

    // Get existing S3 bucket (from previous deployment)
    const webAppBucket = s3.Bucket.fromBucketName(this, 'WebAppBucket', 'basicaustinfoodclubstack-webappbucket8f6fa179-shyzfbe9qamw');

    // Create CloudFront distribution with custom domain
    const distribution = new cloudfront.Distribution(this, 'AustinFoodClubDistribution', {
      defaultBehavior: {
        origin: new origins.S3StaticWebsiteOrigin(webAppBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        originRequestPolicy: cloudfront.OriginRequestPolicy.CORS_S3_ORIGIN,
      },
      domainNames: [domainName],
      certificate: certificate,
      comment: `CloudFront distribution for ${domainName}`,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      httpVersion: cloudfront.HttpVersion.HTTP2,
      enableIpv6: true,
    });

    // Get existing ALB (from ECS stack)
    const alb = elbv2.ApplicationLoadBalancer.fromLookup(this, 'ExistingALB', {
      loadBalancerArn: 'arn:aws:elasticloadbalancing:us-east-1:229037375031:loadbalancer/app/ECSAus-Backe-9BcJbVFKkgWJ/006c12eec76d1aaf',
    });

    // Add HTTPS listener to ALB
    const httpsListener = alb.addListener('HttpsListener', {
      port: 443,
      protocol: elbv2.ApplicationProtocol.HTTPS,
      certificates: [certificate],
      defaultAction: elbv2.ListenerAction.fixedResponse(404, {
        contentType: 'text/plain',
        messageBody: 'Not Found',
      }),
    });

    // Create Route 53 records
    // Main domain points to CloudFront
    new route53.ARecord(this, 'MainDomainRecord', {
      zone: hostedZone,
      recordName: domainName,
      target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(distribution)),
    });

    // API subdomain points to ALB
    new route53.ARecord(this, 'ApiDomainRecord', {
      zone: hostedZone,
      recordName: apiSubdomain,
      target: route53.RecordTarget.fromAlias(new route53Targets.LoadBalancerTarget(alb)),
    });

    // WWW subdomain redirects to main domain
    new route53.CnameRecord(this, 'WwwDomainRecord', {
      zone: hostedZone,
      recordName: `www.${domainName}`,
      domainName: domainName,
    });

    // Outputs
    new cdk.CfnOutput(this, 'HostedZoneId', {
      value: hostedZone.hostedZoneId,
      description: 'Route 53 Hosted Zone ID',
    });

    new cdk.CfnOutput(this, 'NameServers', {
      value: 'Check AWS Console for name servers',
      description: 'Name servers for domain configuration - check Route 53 console',
    });

    new cdk.CfnOutput(this, 'CertificateArn', {
      value: certificate.certificateArn,
      description: 'SSL Certificate ARN',
    });

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront distribution domain name',
    });

    new cdk.CfnOutput(this, 'MainDomainUrl', {
      value: `https://${domainName}`,
      description: 'Main application URL',
    });

    new cdk.CfnOutput(this, 'ApiDomainUrl', {
      value: `https://${apiSubdomain}`,
      description: 'API endpoint URL',
    });
  }
}
