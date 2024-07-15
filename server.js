require('dotenv').config();
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');
const axios = require('axios');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const xss = require('xss-clean');
const hpp = require('hpp');
const morgan = require('morgan');

const app = express();
const port = 3000;

// Set up security middleware
app.use(helmet());
app.use(cors());
app.use(xss());
app.use(hpp());

// Set up rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limit each IP to 100 requests per windowMs
});

// Apply rate limiting to all requests
app.use(limiter);

// Set up morgan for logging
app.use(morgan('combined'));

// Set up multer for handling file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        cb(null, file.fieldname + '-' + Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Set up the route to handle file uploads
app.post('/upload_audio', upload.single('audio'), async (req, res) => {
    try {
        // Validate the uploaded file
        if (!req.file || !req.file.mimetype.startsWith('audio/')) {
            return res.status(400).json({ error: 'Invalid file type' });
        }

        // Process the uploaded audio file
        const filePath = req.file.path;

        // Use the Genius API to search for the song
        const response = await axios.get('https://api.genius.com/search', {
            params: {
                q: 'audio file',
                access_token: process.env.GENIUS_API_TOKEN
            }
        });

        // Extract the song title and artist name from the API response
        const songTitle = response.data.response.hits[0].result.title;
        const artistName = response.data.response.hits[0].result.primary_artist.name;

        // Return the song title and artist name in the response
        res.json({
            songTitle: songTitle,
            artistName: artistName
        });

        // Delete the uploaded audio file
        fs.unlinkSync(filePath);
    } catch (error) {
        console.error('Error processing audio file:', error);
        res.status(500).json({ error: 'Error processing audio file' });
    }
});

// Start the server
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
