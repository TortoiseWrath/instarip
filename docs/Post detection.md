# Instagram posts

Instagram posts: We want just the photo.

## General format
* user
* location (optional) - user and location are to right of profile pic. we have to ignore this for now
* image
* buttons
* Likes row
* **username** description
* comments

We crop from ~3em above the top of the likes row (which has height ~1em) to ~1.05em below bottom of username

Detect username by going down from likes row, finding username in next row, and going up to description

## Likes row

The likes row can read:
* *nnn* likes
* 1 like
* Liked by *user* and *nnn* others
* Liked by *user*
* *nnn* views
* *nnn* views - Liked by *user*
* 1 view
* 1 view - Liked by *user*

## Posts missing bottom

These cannot be detected reliably.

## Posts missing top

We have the likes row and go up until we hit "Instagram" or top of image.

## Photos without description

We go up from likes row until ???

# Twitter posts

Twitter posts: We want the tweet and its author and retweet/like counts.

## Format for tweets with replies
* *name* replied (optional)
* tweeter line
* Replying to @... (optional)
* tweet
* stat line

## Tweeter line

The tweeter line contains:
* profile pic (useless)
* name (useless)
* verification mark? (useless)
* @username
* · (sometimes recognized as :)
* timestamp
* show button (usually recognized as v)

Timestamp formats:
* 59s
* 49m
* 4h
* 2d
* 02 Jan
* 09 Dec 18

## Stat line

GCP seems to return some nonsense. Match against the next tweet instead.