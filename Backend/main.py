from fastapi import FastAPI, HTTPException
from spotify_client import SpotifyClient
from metadata import MetadataReader, MetadataWriter
from models import SearchRequest, MetadataPayload, ReadMetadataRequest, WriteArtworkRequest
from PIL import Image, UnidentifiedImageError
import io
import httpx

app = FastAPI()
spotify = SpotifyClient()
spotify.authenticate()



@app.get("/health",status_code=200)
def health_check():
    """@brief Confirm the backend is running. @return JSON with Health status."""
    resp = {"Health":"ok"}
    return resp


@app.post("/search",status_code=200)
def search(request: SearchRequest):
    """
    @brief Search Spotify for tracks matching the query.
    @param request SearchRequest containing the query string.
    @return JSON with a list of SpotifyTrack objects under key 'Tracks'.
    @throws HTTPException 422 if query is empty.
    """
    query = request.query
    try:
        resp = spotify.search_track(query)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    return {'Tracks': resp}


@app.post("/read-metadata",status_code=200)
def read_metadata(request: ReadMetadataRequest):
    """
    @brief Read and return existing metadata from a local audio file.
    @param request ReadMetadataRequest containing the file path.
    @return JSON with a MetadataPayload under key 'Metadata'.
    @throws HTTPException 404 if file does not exist.
    @throws HTTPException 422 if file format is unsupported.
    """
    path = request.c
    try:
        metadata_reader = MetadataReader(path)
    except ValueError as e:
        if "File does not exist" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        elif "Unsupported file format" in str(e):
            raise HTTPException(status_code=422, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    metadata = metadata_reader.read()
    return {'Metadata': metadata}


@app.post("/write-metadata", status_code=200)
def write_metadata(payload: MetadataPayload):
    """
    @brief Write metadata tags to a local audio file.
    @param payload MetadataPayload containing the file path and tag fields.
    @return JSON with success status.
    @throws HTTPException 404 if file does not exist.
    @throws HTTPException 422 if file format is unsupported.
    """
    try:
        path = payload.file_path
        metadata_writer = MetadataWriter(path)
    except ValueError as e:
        if "File does not exist" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        elif "Unsupported file format" in str(e):
            raise HTTPException(status_code=422, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))
    metadata_writer.write(payload)
    return {'status': "success"}


@app.post("/write-artwork", status_code=200)
def write_artwork(request: WriteArtworkRequest):
    """
    @brief Read artwork from a local image path and embed it into an audio file.
    @param request WriteArtworkRequest containing the audio file path and artwork image path.
    @return JSON with success status.
    @throws HTTPException 404 if either file path does not exist.
    @throws HTTPException 422 if the image file is not a valid format.
    """

    try:
        path = request.file_path
        metadata_writer = MetadataWriter(path)
    except ValueError as e:
        if "File does not exist" in str(e):
            raise HTTPException(status_code=404, detail=str(e))
        elif "Unsupported file format" in str(e):
            raise HTTPException(status_code=422, detail=str(e))
        else:
            raise HTTPException(status_code=400, detail=str(e))

    if request.artwork_path.startswith(("http://", "https://")):
        image = httpx.get(request.artwork_path)
        if image.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch remote artwork")
        image_content = image.content
        buffer = io.BytesIO(image_content)
    else:
        try:
            with open(request.artwork_path, 'rb') as f:
                image_content = f.read()
                buffer = io.BytesIO(image_content)

        except FileNotFoundError as e:
            raise HTTPException(status_code=404, detail=str(e))
    try:
        img = Image.open(buffer)
    except UnidentifiedImageError as e:
        raise HTTPException(status_code=422, detail=str(e))
    img.thumbnail((500, 500))
    output = io.BytesIO()
    img.save(output, format='JPEG')
    compressed_bytes = output.getvalue()
    metadata_writer.write_artwork(compressed_bytes)
    return {'status': "success"}
