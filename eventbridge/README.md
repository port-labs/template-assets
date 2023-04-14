# This is the cloudformation to set up a cloudtrail/eventbridge listener

https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/aws/run-on-events

```
aws cloudformation deploy --template-file eventbridge.yml --stack-name port-aws-exporter-event-rules
```