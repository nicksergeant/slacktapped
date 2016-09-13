# Slacktapped

Slacktapped is an Elixir app to post Untappd activity to Slack.

Once installed, this bot will post checkins, badges, and comments of
friends of the authenticated user to a Slack channel.

## Setup

1. Create an incoming webhook and point it to the channel of your choosing in
   your Slack team.
2. Create a new Untappd user. This user will be a standalone user that the bot
   will authenticate as.
3. For any user whose activity you want this bot to post, have that user friend
   the created Untappd user, and then accept the friendship on Untappd.
4. Create an <a href="https://untappd.com/api/">Untappd API application</a>.
5. <a href="https://redislabs.com/redis-cloud">Obtain</a> or deploy a Redis instance.
   Redis is used to keep track of activity that has been posted to Slack.
6. With your Untappd API credentials, authenticate as your user using the
   <a href="https://untappd.com/api/docs#authentication">"Client Side Authentication" instructions here</a>.
   Make note of the returned `access_token`. Currently Untappd does not expire
   access tokens retrieved in this manner, but we hope to implement proper
   OAuth in the future.
7. Deploy this bot to Heroku or <a href="http://dokku.viewdocs.io/dokku/">Dokku</a>,
   by following the instructions below.

## Deployment

1. Do a `git push` to Heroku or your Dokku server.
2. Set your environment variables:

```
INSTANCE_NAME='desk'     # Unique name for this Slacktapped instance.
REDIS_HOST=''            # Hostname for your Redis isntance.
SLACK_WEBHOOK_URL=''     # Your Slack incoming webhook URL.
UNTAPPD_ACCESS_TOKEN=''  # Token obtained via auth request above.
UNTAPPD_CLIENT_ID=''     # Your Untappd client ID.
UNTAPPD_CLIENT_SECRET='' # Your Untappd client secret.
```

Once you've deployed with the proper credentials, you should start seeing logs
for your application indicating that the processor is running. It will poll
Untappd every 60 seconds for new activity:

```
[Processor] Running...
[Processor] Done.
```

## Support

If you need help deploying or would like to help with features,
<a href="https://github.com/nicksergeant/slacktapped/issues/new">create an issue</a>.
