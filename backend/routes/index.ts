import express, {type Express, type Request, type Response} from 'express';
import { createServer} from "node:http";

const app = express();
const server = createServer(app);
const port = 3000;


app.get('/', (res:Response, req:Request):void => {
  res.send('<h1>Testing</h1>')
})

server.listen(port, ():void => {
    console.log('server running on http://localhost:3000');
});