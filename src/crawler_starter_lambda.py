import boto3
import time

glue = boto3.client('glue')

def lambda_handler(event, context):
    """
    start crawler and wait
    wait to receive: {"CrawlerName": "nome-do-crawler"}
    """
    crawler_name = event.get('CrawlerName')
    
    if not crawler_name:
        raise ValueError("CrawlerName not provided in event")
    
    print(f"Starting crawler: {crawler_name}")
    
    try:
        # start crawler
        glue.start_crawler(Name=crawler_name)
    except glue.exceptions.CrawlerRunningException:
        print(f"Crawler {crawler_name} is already running")
    
    # Polling until crawler ends
    max_attempts = 60  # 30 minutes (30s * 60)
    
    for attempt in range(max_attempts):
        response = glue.get_crawler(Name=crawler_name)
        state = response['Crawler']['State']
        
        print(f"Attempt {attempt + 1}/{max_attempts} - Crawler state: {state}")
        
        if state == 'READY':
            last_crawl = response['Crawler'].get('LastCrawl', {})
            status = last_crawl.get('Status', 'UNKNOWN')
            
            if status == 'SUCCEEDED':
                print(f"Crawler {crawler_name} completed successfully")
                return {
                    'statusCode': 200,
                    'crawler': crawler_name,
                    'status': 'SUCCESS'
                }
            else:
                raise Exception(f"Crawler {crawler_name} failed with status: {status}")
        
        elif state in ['RUNNING', 'STOPPING']:
            time.sleep(30)  # wait 30 seconds
        
        else:
            raise Exception(f"Crawler {crawler_name} in unexpected state: {state}")
    
    raise Exception(f"Crawler {crawler_name} timeout after {max_attempts * 30} seconds")