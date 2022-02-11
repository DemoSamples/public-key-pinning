# Public Key Pinning Samples Project

This demo project contains number of sub projet demo to demonestrate how to generate and use public key pinning in dfferent kind of project.

- Generate self-signed SSL certificate
- Create node app to use generated SSL certificate
- Get public key form the node server

    - By using OpenSSL command
    - By using swift code (terminal swift app)
    - By using java code (executable jar)
    
- Implementing public key pinning / prevent man in the middle  (MITM)  attack.



# Generate self-signed SSL certificate

- Generate private key

> openssl genrsa -out key.pem

<br>

- Generate CSR (certificate signing request) from private key and provide information as per your need.

> openssl req -new -key key.pem -out csr.pem

<br>
- Generate SSL certificate (from csr and private key)

> openssl x509 -req-days 365 -in csr.pem -signkey key.pem -out cert.pem


Here `cert.pem` is the actual SSL Certificate of our interest and will use for node server

Few other userful commands 
- Get validity date from ssl certificate
> openssl x509 -in cert.pem -noout -enddate

<br><br>

**Very important Note**
We need to make sure we securely keep the private key `key.pem`. Same key will be needed to generate new SSL certificate so that the public key will remain same even after certificate renew. Other wise the `public key` that we get during TLS connection from client to server will be different and we may need to change this new `public-key`  in all the other application where we will be implementing  public key pinning.

<br><br>
# Create node app to use generated SSL certificate

First of all make sure your machine is all ok with node js environment.

- Create a node project `https-server`

```bash
    mkdir https-server 
    cd https-server
    npm init -y
```

- We will be creating express app. So install express dependencies

> npm install express --save

- Install nodemon global dependencies so that you can have live reload for node js app

> npm install -g nodemon

- Add script in `package.json` to use nodemon 

```json
"scripts": {
    "start": "nodemon app.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
```

- Add SSL certificates into node app

```
# create certs folder
mkdir certs
```

copy all (key.pem, csr.pem, cert.pem) certificate into this certs folder

- Create `app.js`. This will contain all necessary code to create https server. Copy and paste below code into `app.js` which is pretty straight forward.

```javascript
const express = require('express')
const https = require('https')
const path = require('path')
const fs = require('fs')

const app = express()

app.use('/', (req, res, next) => {
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
```

Here we are using `readFileSync` synchronous versoin of file read method to ensure that all necessary configuration is done before the server is started

<br>

- Run node server
> npm start

- Test if https server is running. For this open the browser and open `https://localhost`. This shoud gives you `Hello from SSL Server` as output.


<br><br>
# Get public key form the node server

### By using OpenSSL command

Make sure the node server is running and run following command.

> openssl s_client -servername localhost  -connect localhost:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

Here we are connecting to localserver. if you want to get public key from real host you can change the server name from `localhost:433` to as per need.

Response from above request is
```
verify return:1
dmlYyj3QuEslhVvbMZWU4myeZuQEr40gem6MkcwgFc0=
read:errno=0
```

`dmlYyj3QuEslhVvbMZWU4myeZuQEr40gem6MkcwgFc0=` is the public key of our interest.

### Public key pinning (node client example)

Now we ready to test the public key pinning in order to prevent MITM attach. First of all we will test in api call by using node js it self. 

- Frist create `client.js` file in our `https-server`
- copy and paste below code in `client.js`

```javascript
const tls = require('tls');
const https = require('https');
const crypto = require('crypto');
const axios = require('axios');

function sha256(s) {
  return crypto.createHash('sha256').update(s).digest('base64');
}

const options = {
 //rejectUnauthorized: true, // for production use
  ca: fs.readFileSync(path.join(__dirname, 'certs','cert.pem')), //for development use case
  checkServerIdentity: function(host, cert) {
    // Make sure the certificate is issued to the host we are connected to
    const err = tls.checkServerIdentity(host, cert);
    if (err) {
      return err;
    }

   

    // Pin the public key, similar to HPKP pin-sha25 pinning
    const pubkey256 = "dmlYyj3QuEslhVvbMZWU4myeZuQEr40gem6MkcwgFc0=";
    console.log(typeof(pubkey256), " -- ", pubkey256)
    
    if (sha256(cert.pubkey) !== pubkey256) {
      return new Error('Certificate verification error 1');
    }

  },
};

const agent = new https.Agent(options);

axios.get('https://localhost', { httpsAgent: agent })
.then(response => {
    console.log('All OK. Server matched our pinned cert or public key')
})
.catch(error => {
    console.error(error.message)
});


```


Here all we need to do is change the `pubkey256` to our public key `dmlYyj3QuEslhVvbMZWU4myeZuQEr40gem6MkcwgFc0=` in option payload.

-  Running `client.js` to test public key pinning. 
> node `client.js`

If you are in development enviroment and using localhost as host then it is require to use 
> ca: fs.readFileSync(path.join(__dirname, 'certs','cert.pem'))

But if you are using in production version then following will also works.
> rejectUnauthorized: true, // for production use


## Commandline syntax to use get public key

>  ./get-public-key api.zakipointhealth.com
