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
    const adminSubdomain = 'admin.austinfoodclub.com';

    // Import existing hosted zone for the domain (avoid creating a new zone)
    const hostedZone = route53.HostedZone.fromLookup(this, 'AustinFoodClubHostedZone', {
      domainName: domainName,
    });

    // Create a CloudFront-compatible certificate in us-east-1
    const cfCertificate = new acm.DnsValidatedCertificate(this, 'AustinFoodClubCfCertificate', {
      domainName: domainName,
      subjectAlternativeNames: [apiSubdomain, adminSubdomain],
      hostedZone: hostedZone,
      region: 'us-east-1',
    });

    // Main site bucket (Flutter web app)
    const webAppBucket = s3.Bucket.fromBucketName(this, 'WebAppBucket', 'austinfoodclub-frontend');

    // Create CloudFront distribution with custom domain
    const distribution = new cloudfront.Distribution(this, 'AustinFoodClubDistribution', {
      defaultBehavior: {
        origin: new origins.S3StaticWebsiteOrigin(webAppBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
        originRequestPolicy: cloudfront.OriginRequestPolicy.CORS_S3_ORIGIN,
      },
      domainNames: [domainName],
      certificate: cfCertificate,
      comment: `CloudFront distribution for ${domainName}`,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      httpVersion: cloudfront.HttpVersion.HTTP2,
      enableIpv6: true,
    });

    // Admin S3 bucket and CloudFront
    const adminBucket = new s3.Bucket(this, 'AdminWebBucket', {
      // private bucket; access via CloudFront OAI
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    const adminOai = new cloudfront.OriginAccessIdentity(this, 'AdminOAI');
    // Allow CloudFront to read from the bucket
    adminBucket.grantRead(adminOai.grantPrincipal);

    const adminDistribution = new cloudfront.Distribution(this, 'AdminDistribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(adminBucket, { originAccessIdentity: adminOai }),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      defaultRootObject: 'admin-dashboard.html',
      domainNames: [adminSubdomain],
      certificate: cfCertificate,
      comment: `CloudFront distribution for ${adminSubdomain}`,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      httpVersion: cloudfront.HttpVersion.HTTP2,
      enableIpv6: true,
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/admin-dashboard.html',
        },
      ],
    });

    // Get existing ALB (from ECS stack)
    const alb = elbv2.ApplicationLoadBalancer.fromLookup(this, 'ExistingALB', {
      loadBalancerArn: 'arn:aws:elasticloadbalancing:us-east-1:229037375031:loadbalancer/app/ECSAus-Backe-9BcJbVFKkgWJ/006c12eec76d1aaf',
    });

    // Add HTTPS listener to ALB
    // HTTPS listener forwards to existing backend target group
    const httpsListener = alb.addListener('HttpsListener', {
      port: 443,
      protocol: elbv2.ApplicationProtocol.HTTPS,
      certificates: [cfCertificate],
      // forward to imported target group
      defaultAction: elbv2.ListenerAction.forward([
        elbv2.ApplicationTargetGroup.fromTargetGroupAttributes(this, 'ImportedBackendTG', {
          targetGroupArn: 'arn:aws:elasticloadbalancing:us-east-1:229037375031:targetgroup/ECSAus-Backe-JOCBBUXAFOVB/ffbf0e7093acbafe',
        }),
      ]),
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

    // Admin subdomain points to admin CloudFront
    new route53.ARecord(this, 'AdminDomainRecord', {
      zone: hostedZone,
      recordName: adminSubdomain,
      target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(adminDistribution)),
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
      value: cfCertificate.certificateArn,
      description: 'SSL Certificate ARN (us-east-1 for CloudFront)',
    });

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront distribution domain name',
    });

    new cdk.CfnOutput(this, 'AdminBucketName', {
      value: adminBucket.bucketName,
      description: 'S3 bucket name for admin dashboard',
    });

    new cdk.CfnOutput(this, 'AdminCloudFrontDomainName', {
      value: adminDistribution.distributionDomainName,
      description: 'CloudFront distribution domain name for admin',
    });

    new cdk.CfnOutput(this, 'MainDomainUrl', {
      value: `https://${domainName}`,
      description: 'Main application URL',
    });

    new cdk.CfnOutput(this, 'ApiDomainUrl', {
      value: `https://${apiSubdomain}`,
      description: 'API endpoint URL',
    });

    new cdk.CfnOutput(this, 'AdminDomainUrl', {
      value: `https://${adminSubdomain}`,
      description: 'Admin dashboard URL',
    });
  }
}
