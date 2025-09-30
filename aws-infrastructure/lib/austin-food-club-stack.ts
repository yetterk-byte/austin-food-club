import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as route53Targets from 'aws-cdk-lib/aws-route53-targets';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class AustinFoodClubStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create VPC for our infrastructure
    const vpc = new ec2.Vpc(this, 'AustinFoodClubVPC', {
      maxAzs: 2,
      natGateways: 1, // Cost optimization - single NAT gateway
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
    });

    // Create security group for RDS
    const dbSecurityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc,
      description: 'Security group for Austin Food Club database',
      allowAllOutbound: false,
    });

    // Create security group for ECS tasks
    const ecsSecurityGroup = new ec2.SecurityGroup(this, 'ECSSecurityGroup', {
      vpc,
      description: 'Security group for Austin Food Club ECS tasks',
      allowAllOutbound: true,
    });

    // Allow ECS tasks to connect to database
    dbSecurityGroup.addIngressRule(
      ecsSecurityGroup,
      ec2.Port.tcp(5432),
      'Allow ECS tasks to connect to PostgreSQL'
    );

    // Create RDS PostgreSQL database
    const database = new rds.DatabaseInstance(this, 'AustinFoodClubDatabase', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_4,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      securityGroups: [dbSecurityGroup],
      databaseName: 'austinfoodclub',
      credentials: rds.Credentials.fromGeneratedSecret('postgres'),
      backupRetention: cdk.Duration.days(7),
      deleteAutomatedBackups: false,
      deletionProtection: false, // Set to true in production
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Change to RETAIN in production
    });

    // Create secrets for application configuration
    const appSecrets = new secretsmanager.Secret(this, 'AppSecrets', {
      description: 'Application secrets for Austin Food Club',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          JWT_SECRET: 'your-jwt-secret-here',
          YELP_API_KEY: 'your-yelp-api-key-here',
        }),
        generateStringKey: 'random-key',
        excludeCharacters: '"@/\\',
      },
    });

    // Create CloudWatch log group
    const logGroup = new logs.LogGroup(this, 'AustinFoodClubLogs', {
      logGroupName: '/aws/ecs/austin-food-club',
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Create ECS cluster
    const cluster = new ecs.Cluster(this, 'AustinFoodClubCluster', {
      vpc,
      clusterName: 'austin-food-club',
    });

    // Create task definition for the backend
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'BackendTaskDefinition', {
      memoryLimitMiB: 512,
      cpu: 256,
    });

    // Add container to task definition
    const container = taskDefinition.addContainer('BackendContainer', {
      image: ecs.ContainerImage.fromRegistry('node:18-alpine'),
      memoryLimitMiB: 512,
      cpu: 256,
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'backend',
        logGroup,
      }),
      environment: {
        NODE_ENV: 'production',
        PORT: '3001',
      },
      secrets: {
        DATABASE_URL: ecs.Secret.fromSecretsManager(database.secret!, 'password'),
        JWT_SECRET: ecs.Secret.fromSecretsManager(appSecrets, 'JWT_SECRET'),
        YELP_API_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'YELP_API_KEY'),
        SUPABASE_URL: ecs.Secret.fromSecretsManager(appSecrets, 'SUPABASE_URL'),
        SUPABASE_ANON_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'SUPABASE_ANON_KEY'),
      },
    });

    container.addPortMappings({
      containerPort: 3001,
      protocol: ecs.Protocol.TCP,
    });

    // Create Application Load Balancer with Fargate service
    const fargateService = new ecsPatterns.ApplicationLoadBalancedFargateService(this, 'BackendService', {
      cluster,
      taskDefinition,
      desiredCount: 1,
      publicLoadBalancer: true,
      securityGroups: [ecsSecurityGroup],
      healthCheckGracePeriod: cdk.Duration.seconds(60),
      listenerPort: 80,
    });

    // Configure health check
    fargateService.targetGroup.configureHealthCheck({
      path: '/api/health',
      healthyHttpCodes: '200',
      interval: cdk.Duration.seconds(30),
      timeout: cdk.Duration.seconds(5),
      healthyThresholdCount: 2,
      unhealthyThresholdCount: 3,
    });

    // Create S3 bucket for Flutter web app
    const webAppBucket = new s3.Bucket(this, 'WebAppBucket', {
      websiteIndexDocument: 'index.html',
      websiteErrorDocument: 'index.html', // For SPA routing
      publicReadAccess: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ACLS,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Create CloudFront distribution for the web app
    const distribution = new cloudfront.Distribution(this, 'WebAppDistribution', {
      defaultBehavior: {
        origin: new origins.S3StaticWebsiteOrigin(webAppBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 404,
          responseHttpStatus: 200,
          responsePagePath: '/index.html',
        },
      ],
    });

    // Create hosted zone for the domain (you'll need to update this with your actual domain)
    const hostedZone = new route53.HostedZone(this, 'AustinFoodClubHostedZone', {
      zoneName: 'austinfoodclub.com',
    });

    // Create SSL certificate
    const certificate = new acm.Certificate(this, 'AustinFoodClubCertificate', {
      domainName: 'austinfoodclub.com',
      subjectAlternativeNames: ['www.austinfoodclub.com'],
      validation: acm.CertificateValidation.fromDns(hostedZone),
    });

    // Create Route53 records
    new route53.ARecord(this, 'WebAppARecord', {
      zone: hostedZone,
      target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(distribution)),
    });

    new route53.ARecord(this, 'WWWWebAppARecord', {
      zone: hostedZone,
      recordName: 'www',
      target: route53.RecordTarget.fromAlias(new route53Targets.CloudFrontTarget(distribution)),
    });

    // Output important values
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'RDS PostgreSQL endpoint',
    });

    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: fargateService.loadBalancer.loadBalancerDnsName,
      description: 'Application Load Balancer DNS name',
    });

    new cdk.CfnOutput(this, 'WebAppBucketName', {
      value: webAppBucket.bucketName,
      description: 'S3 bucket name for web app',
    });

    new cdk.CfnOutput(this, 'CloudFrontDistributionId', {
      value: distribution.distributionId,
      description: 'CloudFront distribution ID',
    });

    new cdk.CfnOutput(this, 'CloudFrontDomainName', {
      value: distribution.distributionDomainName,
      description: 'CloudFront distribution domain name',
    });

    new cdk.CfnOutput(this, 'HostedZoneId', {
      value: hostedZone.hostedZoneId,
      description: 'Route53 hosted zone ID',
    });

    new cdk.CfnOutput(this, 'NameServers', {
      value: hostedZone.hostedZoneNameServers?.join(', ') || 'Not available',
      description: 'Name servers for domain configuration',
    });
  }
}
