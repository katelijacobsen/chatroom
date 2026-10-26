//IMPORTS -----------------------------------------
import express, {type Express, type Request, type Response} from 'express';
import { createServer, type Server as HttpServer } from 'node:http';
import { Server, Socket} from 'socket.io';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import postgres from 'postgres';
//IMPORTS -----------------------------------------

//CONST's -----------------------------------------
const app:Express = express();
const server:HttpServer = createServer(app)
const port = 3000;
// connectionStateRecovery is a feature which temporarily store all events that are sent by the server
// It will try to restore the state of a client when it reconnects.
// Basically the feature will restore its rooms and send any missed events
const io = new Server(server, { connectionStateRecovery: {} })
const __dirname = dirname(fileURLToPath(import.meta.url));

// Connecting to the db
const db= postgres('postgres://katja@127.0.0.1:5432/katja');

//CONST's -----------------------------------------

//EVENT's -----------------------------------------
// Bruger vores decorator til at kunne bruge en af vores HTTP metoder
app.get("/", (req: Request, res:Response): void => {
    res.sendFile(join(__dirname, 'index.html'));
});

// with async we talk to the db. We're telling to wait for the answer before to continue
io.on('connection', async (socket:Socket):Promise<void> => {
    // Checker om vi får besked tilbage fra vores const & inde i vores html
    socket.on('chat msg', async (msg: string, clientOffset: string, callback: () => void):Promise<void> => {
        // We use try & catch if the db fails
        // if it's not running the error is logged instead of crashing the server
        try{
            // Query to Postgres
            const qs = await db `
                                            INSERT INTO messages (
                                            chatroom_id,
                                            user_id,
                                            content,
                                            client_offset
                                            )
                                            VALUES (1, 1, ${msg}, ${clientOffset})
                                            ON CONFLICT (client_offset) DO NOTHING RETURNING id`;

            if(qs.length === 0){
                // retry, send the receipt
                callback();
                return;
            }
            // send the message to everyone, including the sender
            io.emit('chat message', msg, qs[0].id);
            callback();
        } catch (error){
            console.log('Message could not be saved', error);
        }
    });
// if the socket.recovered is false that means the memory feature couldn't handle it.
// The DB would have to handle the failing.
    if(!socket.recovered) {
        try {
            // handshake is the number the browser sent when it connected. It scans. If there is not number then return 0, all msg's
            const failed = await db`SELECT id, content FROM messages WHERE chatroom_id = 1 AND id > ${socket.handshake.auth.serverOffset ?? 0} ORDER BY id`;
            for (const q of failed) {
                socket.emit('chat message', q.content, q.id);
            }
        } catch (error){
            console.log('failed to load the history', error)
        }
    }
})


// Vi lytter til serveren fra vores port af
server.listen(port, ():void => {
    console.log('server running at http://localhost:3000')
})

