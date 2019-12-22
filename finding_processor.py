# Copyright (c) 2016 Amazon Web Services, Inc.

from __future__ import print_function

import json
import os

import boto3

SNS = boto3.client("sns")
INSPECTOR = boto3.client("inspector")

# SNS topic - will be created if it does not already exist
SNS_TOPIC = os.getenv("DELIVERY_SNS_TOPIC")

# Destination email - will be subscribed to the SNS topic if not already
DEST_EMAIL_ADDR = os.getenv("REPORT_EMAIL_TARGET")


def lambda_handler(event, context):
    # extract the message that Inspector sent via SNS
    message = event["Records"][0]["Sns"]["Message"]

    # get inspector notification type
    notification_type = json.loads(message)["event"]

    # skip everything except report_finding notifications
    if notification_type != "FINDING_REPORTED":
        print(f"Skipping notification that is not a new finding: {notification_type}")
        return 1

    # extract finding ARN
    finding_arn = json.loads(message)["finding"]

    # get finding and extract detail
    response = INSPECTOR.describe_findings(findingArns=[finding_arn], locale="EN_US")
    print(response)
    finding = response["findings"][0]

    # skip uninteresting findings
    title = finding["title"]
    if title == "Unsupported Operating System or Version":
        print(f"Skipping finding: {title}")
        return 1

    if title == "No potential security issues found":
        print(f"Skipping finding: {title}")
        return 1

    # get the information to send via email
    subject = title[:100]  # truncate @ 100 chars, SNS subject limit
    message_body = (
        "Title:\n"
        + title
        + "\n\nDescription:\n"
        + finding["description"]
        + "\n\nRecommendation:\n"
        + finding["recommendation"]
    )

    # un-comment the following line to dump the entire finding as raw json
    # messageBody = json.dumps(
    #     finding,
    #     default=lambda obj: (
    #         obj.isoformat() if isinstance(obj, datetime.datetime) or isinstance(obj, datetime.date) else None
    #     ),
    #     indent=2,
    # )

    # create SNS topic if necessary
    response = SNS.create_topic(Name=SNS_TOPIC)
    sns_topic_arn = response["TopicArn"]

    # check to see if the subscription already exists
    subscribed = False
    SNS.list_subscriptions_by_topic(TopicArn=sns_topic_arn)

    next_page_token = ""

    # iterate through subscriptions array in paginated list API call
    while True:
        response = SNS.list_subscriptions_by_topic(TopicArn=sns_topic_arn, NextToken=next_page_token)

        for subscription in response["Subscriptions"]:
            if subscription["Endpoint"] == DEST_EMAIL_ADDR:
                subscribed = True
                break

        if "NextToken" not in response:
            break
        else:
            next_page_token = response["NextToken"]

    # create subscription if necessary
    if not subscribed:
        SNS.subscribe(TopicArn=sns_topic_arn, Protocol="email", Endpoint=DEST_EMAIL_ADDR)

    # publish notification to topic
    SNS.publish(TopicArn=sns_topic_arn, Message=message_body, Subject=subject)

    return 0
