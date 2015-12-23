###
Description:
  Provides stamps (stickers) like LINE in slack.

Dependencies:
  "del": "^2.2.0"
  "request-promise": "^1.0.2"
  "bluebird": "^3.1.1"
  "imagemagick": "^0.1.3"
  "glob": "^6.0.1"
  "node-horseman": "^2.8.2"

Configuration:
  HUBOT_SLACK_STAMP_TEAM_NAME - Slack team name
  HUBOT_SLACK_STAMP_EMAIL - Email for login
  HUBOT_SLACK_STAMP_PASSWORD - Password for login

Commands:
  hubot makestamp <name(a-z,0-9,_,-)> <image_url> <split_num(2-10)> - Register stamp.
  hubot stamp <name> - Display stamp.
  hubot liststamp - Display stamp name list.
  hubot removestamp <name> - Remove stamp.

Notes:
  Two factor authentication is not supported.

Author:
  saihoooooooo <saihoooooooo@gmail.com>
###

fs = require 'fs'
path = require 'path'
del = require 'del'
rp = require 'request-promise'
glob = require 'glob'
Horseman = require('node-horseman')
Promise = require 'bluebird'
im = Promise.promisifyAll require 'imagemagick'

teamName = process.env.HUBOT_SLACK_STAMP_TEAM_NAME
email = process.env.HUBOT_SLACK_STAMP_EMAIL
password = process.env.HUBOT_SLACK_STAMP_PASSWORD

brainKey = 'slack-stamp'

horsemanOption =
  timeout: 60000
  loadImages: false

login = (horseman) ->
  horseman
    .open "https://#{teamName}.slack.com/customize/emoji"
    .type 'input[name="email"]', email
    .type 'input[name="password"]', password
    .click 'button#signin_btn'
    .waitForNextPage()
    .title()
    .then (title) ->
      until /Emoji/.test title
        horseman.close()
        throw new Error 'Error: login failed.'

module.exports = (robot) ->

  robot.respond /liststamp/, (res) ->
    stamps = robot.brain.get brainKey
    until stamps?
      res.send "Stamps are non-registration..."
      return
    res.send Object.keys(stamps).join('\n')

  robot.respond /stamp ([a-z0-9\-_]+)/, (res) ->
    name = res.match[1]
    stamps = robot.brain.get brainKey
    until stamps[name]?
      res.send "#{name} dose not exists..."
      return
    res.send stamps[name]

  robot.respond /makestamp ([a-z0-9\-_]+) (https?:\/\/.*) ([1-9][0-9]?)/, (res) ->
    name = res.match[1]
    url = res.match[2]
    split = res.match[3]

    if name.length > 50
      res.send 'Error: <name> must be less than 50.'
      return
    if robot.brain.get(brainKey)[name]?
      res.send "Error: #{name} is already exists."
      return
    if split < 2 or split > 10
      res.send 'Error: <split> must be 2-10.'
      return

    res.send 'running...'

    imgDir = "#{__dirname}/../img/#{name}"
    originImgPath = "#{imgDir}/origin"
    resizeImgPath = "#{imgDir}/resize"
    cropImgPath = "#{imgDir}/crop"
    pixel = 128
    totalPixel = pixel * split

    exec = ->
      fs.mkdirSync imgDir

      # save image
      body = yield rp
        method: 'GET'
        url: url
        encoding: null
      fs.writeFileSync originImgPath, body, 'binary'

      # crop image
      ext = yield im.identifyAsync ['-format', '%m', originImgPath]
      if ext.trim() not in ['JPEG', 'PNG']
        throw new Error 'Error: Image format must be jpg or png.'
      yield im.convertAsync [originImgPath, '-resize', "#{totalPixel}x#{totalPixel}!", resizeImgPath]
      yield im.convertAsync [resizeImgPath, '-crop', "#{pixel}x#{pixel}", cropImgPath]

      # rename image
      stampImgPathList = []
      for file in glob.sync "#{cropImgPath}*"
        cropNum = file.match(/[0-9]+$/)[0]
        h = Math.floor(cropNum / split) + 1
        w = cropNum % split + 1
        stampImgPath = "#{imgDir}/#{name}_#{split}x#{split}_#{h}-#{w}"
        fs.renameSync file, stampImgPath
        stampImgPathList.push stampImgPath

      # import image
      horseman = new Horseman(horsemanOption)
      yield login(horseman)
      for file in stampImgPathList
        yield horseman
          .type 'input[name="name"]', path.basename file
          .upload 'input[name="img"]', file
          .click 'input[type="submit"]'
          .waitForNextPage()
      horseman.close()

      # save stamp
      stamp = ''
      for i in [1..split]
        stamp += '\n' if stamp != ''
        for j in [1..split]
          stamp += ":#{name}_#{split}x#{split}_#{i}-#{j}:"
      stamps = robot.brain.get(brainKey) or {}
      stamps[name] = stamp
      robot.brain.set brainKey, stamps

      res.send 'done'
      res.send stamp

    Promise.coroutine(exec)()
      .finally -> del.sync imgDir
      .catch (error) -> res.send error.message

  robot.respond /removestamp ([a-z0-9\-_]+)/, (res) ->
    name = res.match[1]
    stamps = robot.brain.get brainKey
    until stamps[name]?
      res.send "#{name} dose not exists..."
      return

    res.send 'running...'

    exec = ->
      for emoji in stamps[name].replace(/(^:|\n|:$)/g, '').split(/::/)
        horseman = new Horseman(horsemanOption)
        yield login(horseman)
        yield horseman
          .evaluate (selector) ->
            $(selector).submit()
          , "form:has(i[data-emoji-name='#{emoji}'])"
          .waitForNextPage()
          .close()

      delete stamps[name]
      robot.brain.set brainKey, stamps
      res.send 'done'

    Promise.coroutine(exec)()
      .catch (error) -> res.send error.message
