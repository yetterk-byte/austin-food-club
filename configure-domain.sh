#!/bin/bash

# Austin Food Club - Domain Configuration Script
# This script helps configure a custom domain for the application

set -e

echo "🌐 Austin Food Club - Domain Configuration"
echo "=========================================="

# Check if domain is provided
if [ -z "$1" ]; then
    echo "❌ Error: Please provide a domain name"
    echo "Usage: ./configure-domain.sh yourdomain.com"
    echo "Example: ./configure-domain.sh austinfoodclub.com"
    exit 1
fi

DOMAIN=$1
API_SUBDOMAIN="api.$DOMAIN"

echo "📋 Domain Configuration:"
echo "  Main Domain: $DOMAIN"
echo "  API Subdomain: $API_SUBDOMAIN"
echo ""

# Update domain stack configuration
echo "🔧 Updating domain configuration..."

# Create a temporary file with updated domain
cat > aws-infrastructure/lib/domain-stack-temp.ts << EOF
import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';

export class DomainAustinFoodClubStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Domain configuration
    const domainName = '$DOMAIN';
    const apiSubdomain = '$API_SUBDOMAIN';

    // Create hosted zone for the domain
    const hostedZone = new route53.HostedZone(this, 'AustinFoodClubHostedZone', {
      zoneName: domainName,
      comment: \`Hosted zone for \${domainName}\`,
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
      comment: \`CloudFront distribution for \${domainName}\`,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
      httpVersion: cloudfront.HttpVersion.HTTP2,
      enableIpv6: true,
    });

    // Get existing ALB (from ECS stack)
    const alb = elbv2.ApplicationLoadBalancer.fromLookup(this, 'ExistingALB', {
      loadBalancerArn: 'arn:aws:elasticloadbalancing:us-east-1:229037375031:loadbalancer/app/ECSAus-Backe-9BcJbVFKkgWJ/1172628832',
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
      recordName: \`www.\${domainName}\`,
      domainName: domainName,
    });

    // Outputs
    new cdk.CfnOutput(this, 'HostedZoneId', {
      value: hostedZone.hostedZoneId,
      description: 'Route 53 Hosted Zone ID',
    });

    new cdk.CfnOutput(this, 'NameServers', {
      value: hostedZone.hostNameServers?.join(', ') || 'Not available',
      description: 'Name servers for domain configuration',
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
      value: \`https://\${domainName}\`,
      description: 'Main application URL',
    });

    new cdk.CfnOutput(this, 'ApiDomainUrl', {
      value: \`https://\${apiSubdomain}\`,
      description: 'API endpoint URL',
    });
  }
}
EOF

# Replace the original file
mv aws-infrastructure/lib/domain-stack-temp.ts aws-infrastructure/lib/domain-stack.ts

echo "✅ Domain configuration updated"
echo ""

# Deploy the domain stack
echo "🚀 Deploying domain configuration..."
cd aws-infrastructure
npx cdk deploy DomainAustinFoodClubStack --require-approval never

echo ""
echo "🎉 Domain configuration deployed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Copy the name servers from the CDK output above"
echo "2. Update your domain registrar with these name servers"
echo "3. Wait for DNS propagation (can take up to 48 hours)"
echo "4. Test your domain: https://$DOMAIN"
echo "5. Test your API: https://$API_SUBDOMAIN/api/health"
echo ""
echo "📖 For detailed instructions, see: DOMAIN_CONFIGURATION_GUIDE.md"

