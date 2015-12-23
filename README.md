# hubot-slack-stamp

Provides stamps (stickers) like LINE in slack.  
Consecutive emoji realizes it.

## Installation

Run the `npm install` command.

```
$ npm install hubot-slack-stamp
```

Add the following code in your `external-scripts.json` file.

```
[
  "hubot-slack-stamp"
]
```

## Requirements

* Node.js >= v4.0.0 (or --harmony or --harmony-generators flag)
* PhantomJS
* ImageMagick

## Usage

#### Register stamp

```
hubot makestamp <name(a-z,0-9,_,-)> <image_url> <split_num(2-10)>
```

(exsample)

![makestamp](https://raw.githubusercontent.com/wiki/splathon/hubot-slack-stamp/image/makestamp.png)

#### Display stamp

```
hubot stamp <name>
```

(exsample)

![stamp](https://raw.githubusercontent.com/wiki/splathon/hubot-slack-stamp/image/stamp.png)

#### Display stamp name list

```
hubot liststamp
```

#### Remove stamp

```
hubot removestamp <name>
```

### Operating principle

`hubot-slack-stamp` crops an image and registers as emoji , and line up neatly and express a stamp.  
Actually , It outputs the following character string.

```
:marie_3x3_1-1::marie_3x3_1-2::marie_3x3_1-3:
:marie_3x3_2-1::marie_3x3_2-2::marie_3x3_2-3:
:marie_3x3_3-1::marie_3x3_3-2::marie_3x3_3-3:
```

![customemoji](https://raw.githubusercontent.com/wiki/splathon/hubot-slack-stamp/image/customemoji.png)

illustration: http://seiga.nicovideo.jp/seiga/im4981228

## Configuration
The following is all required.

* `HUBOT_SLACK_STAMP_TEAM_NAME` - Slack team name
* `HUBOT_SLACK_STAMP_EMAIL` - Email for login
* `HUBOT_SLACK_STAMP_PASSWORD` - Password for login

## Notes

Two factor authentication is not supported.

## License & copyright

Copyright (c) 2015 saihoooooooo.

hobot-slack-stamp is licensed under the MIT license. All rights not explicitly granted in the MIT license are reserved. See the included LICENSE file for more details.
