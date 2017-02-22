"""
AWS SES + Lambda equivalent of discourse/mail-receiver.

Required environment variables:

- S3_BUCKET_NAME
- DISCOURSE_MAIL_ENDPOINT
- DISCOURSE_API_KEY
- DISCOURSE_API_USERNAME
"""
import os
import urllib
import urllib2
import urlparse
import boto3


def handler(event, context):
    bucket_name = os.environ['S3_BUCKET_NAME']
    endpoint = os.environ['DISCOURSE_MAIL_ENDPOINT']
    api_key = os.environ['DISCOURSE_API_KEY']
    api_username = os.environ['DISCOURSE_API_USERNAME']

    ses_notification = event['Records'][0]['ses']
    message_id = ses_notification['mail']['messageId']

    email = get_received_email(bucket_name, message_id)
    url = make_url(endpoint, api_key, api_username)
    response = post_email(email, url)
    print(response.getcode())


def get_received_email(bucket_name, message_id):
    s3 = boto3.resource('s3')

    obj = s3.Object(bucket_name, message_id)
    return obj.get()['Body'].read().decode('utf-8')


def make_url(endpoint, api_key, api_username):
    """
    >>> result = urlparse.urlsplit(make_url("http://example.com/?foo=bar", "xyz", "system"))
    >>> expected = urlparse.urlsplit("http://example.com/?foo=bar&api_key=xyz&api_username=system")
    >>> urlparse.parse_qs(result.query) == urlparse.parse_qs(expected.query)
    True

    """
    parsed = urlparse.urlsplit(endpoint)
    query = urlparse.parse_qs(parsed.query)
    query['api_key'] = api_key
    query['api_username'] = api_username
    return urlparse.urlunsplit((
        parsed.scheme,
        parsed.netloc,
        parsed.path,
        urllib.urlencode(query, doseq=True),
        parsed.fragment,
    ))


def post_email(email, url):
    values = {'email': email}
    data = urllib.urlencode(values)
    req = urllib2.Request(url, data)
    return urllib2.urlopen(req)
