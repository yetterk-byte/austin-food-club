#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { ECSAustinFoodClubStack } from '../lib/ecs-stack';
import { DomainAustinFoodClubStack } from '../lib/domain-stack';
import { MonitoringAustinFoodClubStack } from '../lib/monitoring-stack';

const app = new cdk.App();

// Deploy ECS stack first
new ECSAustinFoodClubStack(app, 'ECSAustinFoodClubStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1' 
  },
  description: 'Austin Food Club - ECS Backend Deployment',
});

// Deploy domain configuration
new DomainAustinFoodClubStack(app, 'DomainAustinFoodClubStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1' 
  },
  description: 'Austin Food Club - Custom Domain Configuration',
});

// Deploy monitoring stack
new MonitoringAustinFoodClubStack(app, 'MonitoringAustinFoodClubStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1' 
  },
  description: 'Austin Food Club - CloudWatch Monitoring',
});