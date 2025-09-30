# 🌐 Custom Domain Configuration Guide

This guide walks you through configuring a custom domain for the Austin Food Club application.

## 📋 Prerequisites

1. **Domain Registration**: You need to own a domain (e.g., `austinfoodclub.com`)
2. **AWS Account**: With appropriate permissions for Route 53, ACM, CloudFront, and ALB
3. **Existing Infrastructure**: ECS stack and S3 bucket must be deployed

## 🚀 Step-by-Step Configuration

### Step 1: Domain Registration

If you don't have a domain yet:

1. **Register Domain**: Use AWS Route 53, GoDaddy, Namecheap, or other registrar
2. **Choose Domain**: Select a domain like `austinfoodclub.com`
3. **Payment**: Complete registration and payment

### Step 2: Update Domain Configuration

Edit the domain stack file:

```typescript
// In aws-infrastructure/lib/domain-stack.ts
const domainName = 'yourdomain.com'; // Replace with your actual domain
const apiSubdomain = 'api.yourdomain.com'; // Replace with your API subdomain
```

### Step 3: Deploy Domain Infrastructure

```bash
# Update CDK app to use domain stack
cd aws-infrastructure

# Deploy the domain configuration
npx cdk deploy DomainAustinFoodClubStack
```

### Step 4: Configure DNS at Your Registrar

After deployment, you'll get name servers from the CDK output:

1. **Copy Name Servers**: From the CDK output
2. **Update Registrar**: Set these as your domain's name servers
3. **Wait for Propagation**: DNS changes can take 24-48 hours

### Step 5: Update Application Configuration

#### Frontend Configuration

Update your Flutter app to use the custom domain:

```dart
// In mobile/lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://api.yourdomain.com';
  static const String webUrl = 'https://yourdomain.com';
}
```

#### Backend Configuration

Update CORS settings for the custom domain:

```javascript
// In server/src/server.js
const corsOptions = {
  origin: [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
    'http://localhost:3000', // Keep for development
  ],
  credentials: true,
};
```

### Step 6: SSL Certificate Validation

The ACM certificate will automatically validate using DNS:

1. **Check Certificate Status**: In AWS Console → Certificate Manager
2. **Wait for Validation**: Usually takes 5-10 minutes
3. **Verify Status**: Should show "Issued" when ready

### Step 7: Test Domain Configuration

```bash
# Test main domain
curl -I https://yourdomain.com

# Test API subdomain
curl -I https://api.yourdomain.com/api/health

# Test SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

## 🔧 Advanced Configuration

### Custom Error Pages

Configure custom error pages in CloudFront:

```typescript
// Add to CloudFront distribution
errorResponses: [
  {
    httpStatus: 404,
    responseHttpStatus: 200,
    responsePagePath: '/index.html',
  },
  {
    httpStatus: 403,
    responseHttpStatus: 200,
    responsePagePath: '/index.html',
  },
],
```

### Subdomain Configuration

Add additional subdomains:

```typescript
// Add to certificate
subjectAlternativeNames: [
  'api.yourdomain.com',
  'admin.yourdomain.com',
  'staging.yourdomain.com',
],

// Add Route 53 records
new route53.ARecord(this, 'AdminDomainRecord', {
  zone: hostedZone,
  recordName: 'admin.yourdomain.com',
  target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(distribution)),
});
```

### CDN Optimization

Configure CloudFront for better performance:

```typescript
// Add caching behaviors
additionalBehaviors: {
  '/api/*': {
    origin: new origins.LoadBalancerV2Origin(alb),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.HTTPS_ONLY,
    cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
    originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER,
  },
},
```

## 🔍 Troubleshooting

### Common Issues

1. **Certificate Not Validating**
   - Check DNS propagation: `dig NS yourdomain.com`
   - Verify name servers are set correctly
   - Wait for DNS propagation (up to 48 hours)

2. **Domain Not Resolving**
   - Check Route 53 records: `dig yourdomain.com`
   - Verify CloudFront distribution is deployed
   - Check ALB health status

3. **SSL Certificate Errors**
   - Verify certificate is attached to CloudFront
   - Check certificate covers all subdomains
   - Ensure certificate is in `us-east-1` region

4. **CORS Issues**
   - Update backend CORS configuration
   - Check preflight requests
   - Verify credentials are handled correctly

### Debugging Commands

```bash
# Check DNS resolution
nslookup yourdomain.com
dig yourdomain.com A

# Check SSL certificate
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com

# Test API endpoint
curl -v https://api.yourdomain.com/api/health

# Check CloudFront distribution
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID
```

## 📊 Monitoring

### CloudWatch Metrics

Monitor your domain:

1. **Route 53 Health Checks**: Set up health checks for your domain
2. **CloudFront Metrics**: Monitor cache hit rates and errors
3. **ALB Metrics**: Track backend performance and errors

### Alerts

Set up CloudWatch alarms for:

- High error rates
- Certificate expiration
- DNS resolution failures
- Backend health check failures

## 🎯 Next Steps

After domain configuration:

1. **Update Environment Variables**: Set production URLs
2. **Configure Monitoring**: Set up CloudWatch alarms
3. **Test End-to-End**: Verify all functionality works
4. **Update Documentation**: Document the production URLs
5. **Set Up CI/CD**: Automate deployments to production

## 💰 Cost Considerations

- **Route 53**: $0.50/month per hosted zone + $0.40/million queries
- **ACM**: Free for AWS services
- **CloudFront**: Pay per request and data transfer
- **ALB**: $16.20/month + $0.008 per LCU-hour

Total estimated cost: ~$20-30/month for basic usage.

