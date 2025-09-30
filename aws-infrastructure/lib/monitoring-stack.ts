import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';

export class MonitoringAustinFoodClubStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // SNS Topic for alerts
    const alertTopic = new sns.Topic(this, 'AlertTopic', {
      topicName: 'austin-food-club-alerts',
      displayName: 'Austin Food Club Alerts',
    });

    // CloudWatch Log Groups
    const applicationLogGroup = new logs.LogGroup(this, 'ApplicationLogGroup', {
      logGroupName: '/aws/ecs/austin-food-club/application',
      retention: logs.RetentionDays.TWO_WEEKS,
    });

    const accessLogGroup = new logs.LogGroup(this, 'AccessLogGroup', {
      logGroupName: '/aws/ecs/austin-food-club/access',
      retention: logs.RetentionDays.ONE_WEEK,
    });

    const errorLogGroup = new logs.LogGroup(this, 'ErrorLogGroup', {
      logGroupName: '/aws/ecs/austin-food-club/errors',
      retention: logs.RetentionDays.ONE_MONTH,
    });

    // CloudWatch Dashboard
    const dashboard = new cloudwatch.Dashboard(this, 'AustinFoodClubDashboard', {
      dashboardName: 'Austin-Food-Club-Production',
    });

    // ECS Service Metrics
    const ecsClusterName = 'austin-food-club-cluster';
    const ecsServiceName = 'austin-food-club-backend';

    // CPU Utilization
    const cpuUtilization = new cloudwatch.Metric({
      namespace: 'AWS/ECS',
      metricName: 'CPUUtilization',
      dimensionsMap: {
        ServiceName: ecsServiceName,
        ClusterName: ecsClusterName,
      },
      statistic: 'Average',
      period: cdk.Duration.minutes(5),
    });

    // Memory Utilization
    const memoryUtilization = new cloudwatch.Metric({
      namespace: 'AWS/ECS',
      metricName: 'MemoryUtilization',
      dimensionsMap: {
        ServiceName: ecsServiceName,
        ClusterName: ecsClusterName,
      },
      statistic: 'Average',
      period: cdk.Duration.minutes(5),
    });

    // ALB Metrics - Get from existing ALB
    const albName = 'ECSAus-Backe-9BcJbVFKkgWJ'; // This will be updated with actual ALB name
    
    const albRequestCount = new cloudwatch.Metric({
      namespace: 'AWS/ApplicationELB',
      metricName: 'RequestCount',
      dimensionsMap: {
        LoadBalancer: albName,
      },
      statistic: 'Sum',
      period: cdk.Duration.minutes(1),
    });

    const albResponseTime = new cloudwatch.Metric({
      namespace: 'AWS/ApplicationELB',
      metricName: 'TargetResponseTime',
      dimensionsMap: {
        LoadBalancer: albName,
      },
      statistic: 'Average',
      period: cdk.Duration.minutes(1),
    });

    const albErrorRate = new cloudwatch.Metric({
      namespace: 'AWS/ApplicationELB',
      metricName: 'HTTPCode_Target_5XX_Count',
      dimensionsMap: {
        LoadBalancer: albName,
      },
      statistic: 'Sum',
      period: cdk.Duration.minutes(1),
    });

    // RDS Metrics
    const rdsInstanceId = 'ecsaustinfoodclubstack-databaseb269d8bb-md52w78dfjlx';
    
    const rdsCpuUtilization = new cloudwatch.Metric({
      namespace: 'AWS/RDS',
      metricName: 'CPUUtilization',
      dimensionsMap: {
        DBInstanceIdentifier: rdsInstanceId,
      },
      statistic: 'Average',
      period: cdk.Duration.minutes(5),
    });

    const rdsConnections = new cloudwatch.Metric({
      namespace: 'AWS/RDS',
      metricName: 'DatabaseConnections',
      dimensionsMap: {
        DBInstanceIdentifier: rdsInstanceId,
      },
      statistic: 'Average',
      period: cdk.Duration.minutes(5),
    });

    // CloudFront Metrics
    const cloudFrontDistributionId = 'E1234567890ABC'; // This will be updated with actual ID
    
    const cloudFrontRequests = new cloudwatch.Metric({
      namespace: 'AWS/CloudFront',
      metricName: 'Requests',
      dimensionsMap: {
        DistributionId: cloudFrontDistributionId,
      },
      statistic: 'Sum',
      period: cdk.Duration.minutes(5),
    });

    // Custom Application Metrics
    const apiResponseTime = new cloudwatch.Metric({
      namespace: 'AustinFoodClub/API',
      metricName: 'ResponseTime',
      statistic: 'Average',
      period: cdk.Duration.minutes(1),
    });

    const apiErrorCount = new cloudwatch.Metric({
      namespace: 'AustinFoodClub/API',
      metricName: 'ErrorCount',
      statistic: 'Sum',
      period: cdk.Duration.minutes(1),
    });

    const restaurantQueueSize = new cloudwatch.Metric({
      namespace: 'AustinFoodClub/Restaurants',
      metricName: 'QueueSize',
      statistic: 'Average',
      period: cdk.Duration.minutes(5),
    });

    // Alarms
    // High CPU Usage
    const highCpuAlarm = new cloudwatch.Alarm(this, 'HighCpuAlarm', {
      metric: cpuUtilization,
      threshold: 80,
      evaluationPeriods: 2,
      alarmDescription: 'High CPU utilization on ECS service',
      alarmName: 'austin-food-club-high-cpu',
    });

    // High Memory Usage
    const highMemoryAlarm = new cloudwatch.Alarm(this, 'HighMemoryAlarm', {
      metric: memoryUtilization,
      threshold: 85,
      evaluationPeriods: 2,
      alarmDescription: 'High memory utilization on ECS service',
      alarmName: 'austin-food-club-high-memory',
    });

    // High Response Time
    const highResponseTimeAlarm = new cloudwatch.Alarm(this, 'HighResponseTimeAlarm', {
      metric: albResponseTime,
      threshold: 2, // 2 seconds
      evaluationPeriods: 3,
      alarmDescription: 'High response time on ALB',
      alarmName: 'austin-food-club-high-response-time',
    });

    // High Error Rate
    const highErrorRateAlarm = new cloudwatch.Alarm(this, 'HighErrorRateAlarm', {
      metric: albErrorRate,
      threshold: 10, // 10 errors per minute
      evaluationPeriods: 2,
      alarmDescription: 'High error rate on ALB',
      alarmName: 'austin-food-club-high-error-rate',
    });

    // RDS High CPU
    const rdsHighCpuAlarm = new cloudwatch.Alarm(this, 'RdsHighCpuAlarm', {
      metric: rdsCpuUtilization,
      threshold: 75,
      evaluationPeriods: 2,
      alarmDescription: 'High CPU utilization on RDS',
      alarmName: 'austin-food-club-rds-high-cpu',
    });

    // Add SNS actions to alarms
    highCpuAlarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));
    highMemoryAlarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));
    highResponseTimeAlarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));
    highErrorRateAlarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));
    rdsHighCpuAlarm.addAlarmAction(new cloudwatchActions.SnsAction(alertTopic));

    // Dashboard Widgets
    dashboard.addWidgets(
      new cloudwatch.GraphWidget({
        title: 'ECS Service Metrics',
        left: [cpuUtilization, memoryUtilization],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'ALB Metrics',
        left: [albRequestCount, albResponseTime],
        right: [albErrorRate],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'RDS Metrics',
        left: [rdsCpuUtilization, rdsConnections],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'Application Metrics',
        left: [apiResponseTime, restaurantQueueSize],
        right: [apiErrorCount],
        width: 12,
        height: 6,
      }),
      new cloudwatch.GraphWidget({
        title: 'CloudFront Requests',
        left: [cloudFrontRequests],
        width: 12,
        height: 6,
      })
    );

    // Outputs
    new cdk.CfnOutput(this, 'AlertTopicArn', {
      value: alertTopic.topicArn,
      description: 'SNS Topic ARN for alerts',
    });

    new cdk.CfnOutput(this, 'DashboardUrl', {
      value: `https://console.aws.amazon.com/cloudwatch/home?region=${this.region}#dashboards:name=${dashboard.dashboardName}`,
      description: 'CloudWatch Dashboard URL',
    });

    new cdk.CfnOutput(this, 'LogGroupNames', {
      value: `${applicationLogGroup.logGroupName}, ${accessLogGroup.logGroupName}, ${errorLogGroup.logGroupName}`,
      description: 'CloudWatch Log Group Names',
    });
  }
}
