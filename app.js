document.getElementById('record-button').addEventListener('click', async () => {
    if (!isUserLoggedIn()) {
        // User is not logged in, show login prompt
        document.getElementById('login-prompt').style.display = 'block';
    } else {
        // User is logged in, proceed to record and recognize song
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            const audioRecorder = new MediaRecorder(stream);
            audioRecorder.start();

            // Set up the recording timer
            setTimeout(() => {
                // Stop recording after 10 seconds
                audioRecorder.stop();
                const recordedAudio = new Blob([audioRecorder.recordedBlobs[0]], { type: 'audio/wav' });

                // Make an AJAX request to the server to upload and process the audio file
                fetch('/upload_audio', {
                    method: 'POST',
                    body: recordedAudio
                })
                .then(response => response.json())
                .then(data => {
                    console.log('Song recognition result:', data);
                    // Update the UI with the song information
                    const songTitle = data.songTitle;
                    const artistName = data.artistName;

                    // Search for the song on Spotify
                    searchSongOnSpotify(songTitle, artistName);
                })
                .catch(error => console.error('Error uploading audio:', error));
            }, 10000);
        } catch (error) {
            console.error('Error recording audio:', error);
        }
    }
});

// Add event listener to Facebook authentication button
document.getElementById('facebook-auth-button').addEventListener('click', () => {
    // Initialize Facebook authentication
    FB.init({
        appId: '488130147010465',
        cookie: true,
        xfbml: true,
        version: 'v15.0' // updated to latest version
    });

    // Login with Facebook
    FB.login(response => {
        if (response.authResponse) {
            // User is logged in, hide login prompt and proceed to record
            document.getElementById('login-prompt').style.display = 'none';
            recordAndRecognizeSong();
        } else {
            console.log('User cancelled login or did not fully authorize.');
        }
    }, { scope: 'public_profile,email' });
});

// Add event listener to Google authentication button
document.getElementById('google-auth-button').addEventListener('click', () => {
    // Initialize Google authentication
    gapi.load('auth2', () => {
        gapi.auth2.init({
            client_id: '677617571927',
            scope: 'profile email'
        });

        // Login with Google
        gapi.auth2.getAuthInstance().signIn().then(() => {
            // User is logged in, hide login prompt and proceed to record
            document.getElementById('login-prompt').style.display = 'none';
            recordAndRecognizeSong();
        }, error => {
            console.error('Error logging in with Google:', error);
        });
    });
});

// Move the record and recognize song functionality to a separate function
function recordAndRecognizeSong() {
    // Record audio from microphone
    navigator.mediaDevices.getUserMedia({ audio: true })
    .then(stream => {
        const audioRecorder = new MediaRecorder(stream);
        audioRecorder.start();

        // Record audio for 10 seconds
        setTimeout(() => {
            audioRecorder.stop();
            const recordedAudio = new Blob([audioRecorder.recordedBlobs[0]], { type: 'audio/wav' });

            // Make an AJAX request to the server to upload and process the audio file
            fetch('/upload_audio', {
                method: 'POST',
                body: recordedAudio
            })
            .then(response => response.json())
            .then(data => {
                console.log('Song recognition result:', data);
                // Update the UI with the song information
                const songTitle = data.songTitle;
                const artistName = data.artistName;

                // Search for the song on Spotify
                searchSongOnSpotify(songTitle, artistName);
            })
            .catch(error => console.error('Error uploading audio:', error));
        }, 10000);
    })
    .catch(error => console.error('Error recording audio:', error));    
}

// Check if user is logged in with Facebook or Google
function isUserLoggedIn() {
    return FB.getAuthResponse() || gapi.auth2.getAuthInstance().isSignedIn.get();
}

// Search for songs on Spotify
function searchSongOnSpotify(songTitle, artistName) {
    const spotifyApiUrl = 'https://api.spotify.com/v1/search/tracks';
    const apiKey = 'f82b3bb5008e449b83832ba241b30ef7';
    const apiSecret = '0c87e84a36aa41079f0df8886bd9795b';

    // Set up the API request headers
    const headers = new Headers({
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
    });

    // Set up the API request parameters
    const params = new URLSearchParams({
        'q': `${songTitle} ${artistName}`,
        'type': 'track'
    });

    // Make the API request to search for songs
    fetch(`${spotifyApiUrl}?${params}`, {
        method: 'GET',
        headers: headers
    })
    .then(response => response.json())
    .then(data => {
        // Extract the first search result
        const track = data.tracks.items[0];

        // Update the UI with the song information
        document.getElementById('song-title').textContent = track.name;
        document.getElementById('artist-name').textContent = track.artists[0].name;

        // Add a button to download the song
        const downloadButton = document.createElement('button');
        downloadButton.textContent = 'Download';
        downloadButton.addEventListener('click', () => {
            // Make an API request to download the song
            fetch(`https://api.spotify.com/v1/tracks/${track.id}`, {
                method: 'GET',
                headers: headers
            })
            .then(response => response.blob())
            .then(blob => {
                // Create a URL for the blob and download it
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `${track.name}.mp3`;
                a.click();
            });
        });

        // Add the download button to the UI
        document.getElementById('music-info').appendChild(downloadButton);
    })
    .catch(error => console.error('Error searching for song on Spotify:', error));
}

// Add event listener to the speak button
document.getElementById('speak-button').addEventListener('click', () => {
    const songTitle = document.getElementById('song-input').value;
    if (songTitle) {
        // Create a new speech synthesis utterance
        const utterance = new SpeechSynthesisUtterance(songTitle);

        // Speak the song title
        window.speechSynthesis.speak(utterance);
    }
});
