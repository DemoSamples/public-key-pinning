const tls = require('tls');
const https = require('https');
const crypto = require('crypto');
const axios = require('axios');
const fs = require('fs')
const path = require('path')

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
    //console.log(typeof(sha256(cert.pubkey)),  " -- ", sha256(cert.pubkey))
    
    if (sha256(cert.pubkey) !== pubkey256) {
      return new Error('Certificate verification error 1');
    }

    /*
    // OR Pin the exact certificate, rather than the pub key
    const cert256 = '3A:AE:0A:71:39:2F:86:22:5E:F2:9F:A9:FE:0C:66:BD:' +
      '8A:85:AB:F5:C6:8F:F2:D1:E3:33:A8:EF:6F:EB:52:87';
      console.log(typeof(pubkey256), " -- ", cert256)
      console.log(typeof(sha256(cert.pubkey)),  " -- ", cert.fingerprint256)

    if (cert.fingerprint256 !== cert256) {
      return new Error('Certificate verification error 2');
    }
    */
  },
};

const agent = new https.Agent(options);

axios.get('https://localhost', { httpsAgent: agent })
.then((response) => {
    console.log('All OK. Server matched our pinned cert or public key')
    console.log(response.data)
})
.catch(error => {
    console.error("SSL Error", error.message)
});



// https.get('https://localhost', (res) => {
//   console.log('>>>>>>> statusCode:', res.statusCode);
//   console.log('>>>>>>>>> headers:', res.headers);
// })