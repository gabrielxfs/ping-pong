const express = require('express');
const app = express();
const fs = require('fs');
const port = parseInt(process.argv[2]) != NaN ?
  parseInt(process.argv[2]) : 2323;

async function logRestCalls(content) {
  try {
    fs.appendFile('knocknock.log', content, (err) => {
      if (err) {
        console.error(err);
      }
    });
  } catch (err) {
      console.log(err);
  } finally {
      console.log(content);
  }
}

app.use(express.json()) // for parsing application/json
app.use(express.urlencoded({ extended: true })) // for parsing application/x-www-form-urlencoded

app.all(/.*/, (req, res) => {
    let content = '\n';
    content += 'URL ' + req.url + '\n';
    content += 'Method ' + req.method + '\n';
    content += 'Body ' + JSON.stringify(req.body) + '\n';
    content += '--------------------------------------------\n';
    logRestCalls(content);
    res.send('.Okkie Dokkie.');
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
});
