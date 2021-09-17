const express = require('express')
const https = require('https')
const path = require('path')
const fs = require('fs')

const app = express()

app.use('/', (req, res, next) => {
    console.log("new request ");
    res.send('Hello from SSL Server')
})

const sslServer = https.createServer(
    {
    key:fs.readFileSync(path.join(__dirname, 'certs','key.pem')),
    cert:fs.readFileSync(path.join(__dirname,'certs', 'cert.pem'))
    },
    app)

sslServer.listen(443, ()=> {
    console.log("Secure Server on port 443");
})    