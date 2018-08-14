import boto3
import ConfigParser
import botocore
import datetime
import re
import collections

config = ConfigParser.RawConfigParser()
config.read('./vars.ini')

print('Loading Backup function')

def lambda_handler(event, context):
    regionsStrg = config.get('regions', 'regionList')
    regionsList = regionsStrg.split(',')
    instances = []
    for r in regionsList:
        aws_region = r
        print("Checking Region %s" % aws_region)
        account = event['account']
        ec = boto3.client('ec2', region_name=aws_region)
        reservations = ec.describe_instances(
            Filters=[
                {'Name': 'tag:Ephemeral', 'Values': ['False']},
                {'Name': 'tag:Pausable', 'Values': ['True']},
                {'Name': 'instance-state-name', 'Values': [
                    'pending',
                    'running',
                    'shutting-down',
                    'stopping',
                    'stopped',
                ]},
            ]
        )['Reservations']

        for reservation in reservations:
            for instance in reservation["Instances"]:
                instances.append(instance["InstanceId"])

        ec.stop_instances(InstanceIds=instances)
        print("Stopped %i instance/s" % len(instances))
