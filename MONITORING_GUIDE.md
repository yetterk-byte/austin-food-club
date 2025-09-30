# 📊 CloudWatch Monitoring Guide

This guide covers the comprehensive monitoring setup for the Austin Food Club application deployed on AWS.

## 🎯 **Monitoring Overview**

Your Austin Food Club application now has complete CloudWatch monitoring including:

- **Real-time Metrics**: CPU, Memory, Response Times, Error Rates
- **Automated Alerts**: SNS notifications for critical issues
- **Centralized Logging**: Application, Access, and Error logs
- **Custom Dashboard**: Visual monitoring of all key metrics

## 📈 **CloudWatch Dashboard**

**Dashboard URL**: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=Austin-Food-Club-Production

### **Dashboard Sections:**

1. **ECS Service Metrics**
   - CPU Utilization
   - Memory Utilization
   - Container Health

2. **ALB Metrics**
   - Request Count
   - Response Time
   - Error Rate (5XX responses)

3. **RDS Metrics**
   - Database CPU Usage
   - Active Connections
   - Storage Utilization

4. **Application Metrics**
   - API Response Times
   - Restaurant Queue Size
   - Error Count

5. **CloudFront Metrics**
   - Request Volume
   - Cache Hit Ratio
   - Data Transfer

## 🚨 **Alert Configuration**

### **SNS Topic**: `austin-food-club-alerts`
**ARN**: `arn:aws:sns:us-east-1:229037375031:austin-food-club-alerts`

### **Active Alarms:**

1. **High CPU Usage** (`austin-food-club-high-cpu`)
   - **Threshold**: 80% CPU utilization
   - **Evaluation**: 2 periods of 5 minutes
   - **Action**: SNS notification

2. **High Memory Usage** (`austin-food-club-high-memory`)
   - **Threshold**: 85% memory utilization
   - **Evaluation**: 2 periods of 5 minutes
   - **Action**: SNS notification

3. **High Response Time** (`austin-food-club-high-response-time`)
   - **Threshold**: 2 seconds average response time
   - **Evaluation**: 3 periods of 1 minute
   - **Action**: SNS notification

4. **High Error Rate** (`austin-food-club-high-error-rate`)
   - **Threshold**: 10 errors per minute
   - **Evaluation**: 2 periods of 1 minute
   - **Action**: SNS notification

5. **RDS High CPU** (`austin-food-club-rds-high-cpu`)
   - **Threshold**: 75% CPU utilization
   - **Evaluation**: 2 periods of 5 minutes
   - **Action**: SNS notification

## 📝 **Log Groups**

### **Application Logs**
- **Log Group**: `/aws/ecs/austin-food-club/application`
- **Retention**: 2 weeks
- **Contains**: Application logs, business logic logs

### **Access Logs**
- **Log Group**: `/aws/ecs/austin-food-club/access`
- **Retention**: 1 week
- **Contains**: HTTP request logs, API access logs

### **Error Logs**
- **Log Group**: `/aws/ecs/austin-food-club/errors`
- **Retention**: 1 month
- **Contains**: Error logs, exception traces

## 🔧 **Custom Metrics**

The application can send custom metrics to CloudWatch:

### **Namespace**: `AustinFoodClub/API`
- **ResponseTime**: Average API response time
- **ErrorCount**: Number of API errors

### **Namespace**: `AustinFoodClub/Restaurants`
- **QueueSize**: Current restaurant queue size
- **FeaturedRestaurant**: Currently featured restaurant

## 📱 **Setting Up Email Notifications**

To receive email alerts, subscribe to the SNS topic:

```bash
# Subscribe your email to alerts
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:229037375031:austin-food-club-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 🎛️ **Monitoring Best Practices**

### **Daily Monitoring Tasks:**
1. Check CloudWatch Dashboard for any anomalies
2. Review error logs for new issues
3. Monitor response times during peak hours
4. Check RDS connection count

### **Weekly Monitoring Tasks:**
1. Review alarm history
2. Analyze performance trends
3. Check log retention and cleanup
4. Review cost implications

### **Monthly Monitoring Tasks:**
1. Update alarm thresholds based on usage patterns
2. Review and optimize log retention policies
3. Analyze capacity planning metrics
4. Update monitoring documentation

## 🚀 **Scaling Alerts**

Consider adding these additional alarms as your application grows:

1. **Auto Scaling Alerts**
   - ECS service scaling events
   - Target group health

2. **Cost Monitoring**
   - Daily AWS spend alerts
   - Resource utilization costs

3. **Security Monitoring**
   - Failed authentication attempts
   - Unusual traffic patterns

## 📊 **Performance Optimization**

### **Key Metrics to Watch:**
- **Response Time**: Should be < 500ms for most API calls
- **Error Rate**: Should be < 1% of total requests
- **CPU Usage**: Should stay below 70% under normal load
- **Memory Usage**: Should stay below 80% under normal load

### **Scaling Triggers:**
- CPU > 70% for 5 minutes → Scale up
- Response time > 1s for 3 minutes → Scale up
- Error rate > 5% for 2 minutes → Investigate immediately

## 🔍 **Troubleshooting Guide**

### **High CPU Usage:**
1. Check CloudWatch logs for inefficient queries
2. Review application performance
3. Consider scaling up ECS tasks

### **High Response Time:**
1. Check RDS performance
2. Review ALB target health
3. Analyze application logs for bottlenecks

### **High Error Rate:**
1. Check error logs for patterns
2. Review recent deployments
3. Check external service dependencies

## 📞 **Emergency Contacts**

- **SNS Topic**: `austin-food-club-alerts`
- **Dashboard**: Austin-Food-Club-Production
- **Log Groups**: `/aws/ecs/austin-food-club/*`

## 🎉 **Success!**

Your Austin Food Club application now has enterprise-grade monitoring! The system will automatically alert you to any issues and provide comprehensive visibility into your application's performance.

---

**Next Steps:**
1. Subscribe to email notifications for alerts
2. Bookmark the CloudWatch Dashboard
3. Set up regular monitoring routines
4. Consider adding custom metrics for business KPIs

