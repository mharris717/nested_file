function watch() {
  const fs = require("fs")

  for (var dir of ['../lib','../spec']) {
    fs.watch(dir, {recursive: true}, (event,filename) => {
      console.log("Running tests after mod to ",filename)
      testNotify()
    })
  }

  testNotify()
}

var lastTitle = null
function notify(title,message) {
  const notifier = require('node-notifier');
  const path = require('path')

  title = title || process.argv[3]
  const icon = (title == 'Failure') ? "red.png" : "green.gif"
  var sound = (title == 'Failure') ? 'Basso' : false
  if (lastTitle == 'Failure' && title == 'Success') sound = 'Blow'
  const dt = new Date()
  const dtStr = `${dt.getHours()}:${dt.getMinutes()}:${dt.getSeconds()}`
  const fullMessage = dtStr + ' ' + (message||'')
  lastTitle = title

  notifier.notify({
    'title': title,
    'message': fullMessage,
    icon: path.join(__dirname,icon),
    sound: sound
  });
}

function testNotify() {
  const spawn = require('child_process').spawn;
  // var test = spawn("npm",['test'])
  var test = spawn('bundle',['exec','rspec','-f','d'], {
    cwd: "/code/orig/nested_file"
  })

  test.on('close', (err) => {
    if (err == 0) notify('Success');
    else notify('Failure')
  })

  // mirror output to terminal
  test.stdout.on('data', (data) => {
    const str = ''+data
    if (str.trim() != '') console.log(str.trimRight())
  })
  test.stderr.on('data', (data) => {
    const str = ''+data
    if (str.trim() != '') console.log(str.trimRight())
  })
}

watch()