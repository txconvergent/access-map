const express = require('express')
const app = express()
const port = 5000

app.get('/api_call', (req, res) => res.send({message: 'Hello World!'}))

app.listen(port, () => console.log(`Listening on port ${port}.`))