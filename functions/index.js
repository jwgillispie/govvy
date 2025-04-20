const functions = require("firebase-functions");
const axios = require("axios");
const cors = require("cors")({origin: true});

// Cicero API proxy
exports.ciceroProxy = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      // Get parameters from the request
      const lat = request.query.lat;
      const lon = request.query.lon;
      const city = request.query.city;
      const address = request.query.address;
      const lastName = request.query.lastName;
      const firstName = request.query.firstName;

      // API key stored in Firebase environment
      const CICERO_API_KEY = process.env.CICERO_API_KEY ||
      functions.config().cicero.key;

      if (!CICERO_API_KEY) {
        throw new Error("Cicero API key not configured");
      }

      // Build request parameters
      const params = {
        format: "json",
        key: CICERO_API_KEY,
        max: 100,
      };

      // Add relevant parameters based on search type
      if (lat && lon) {
        params.lat = lat;
        params.lon = lon;
      } else if (city) {
        params.search_loc = city;
      } else if (address) {
        params.search_loc = address;
      } else if (lastName) {
        params.last_name = lastName;
        if (firstName) {
          params.first_name = firstName;
        }
        params.valid_range = "ALL";
      } else {
        throw new Error("Missing required parameters");
      }

      // Make the request to Cicero API
      const ciceroResponse = await axios.get("https://cicero.azavea.com/v3.1/official", {
        params: params,
      });

      // Return the data
      response.json(ciceroResponse.data);
    } catch (error) {
      console.error("Proxy error:", error);
      response.status(500).json({
        error: error.message,
        status: "error",
      });
    }
  });
});

// Google Geocoding API proxy (for city-to-coordinates)
exports.geocodeProxy = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      const address = request.query.address;

      if (!address) {
        throw new Error("Address parameter is required");
      }

      const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY ||
      functions.config().google.maps_key;
      if (!GOOGLE_MAPS_API_KEY) {
        throw new Error("Google Maps API key not configured");
      }

      const geocodeResponse = await axios.get("https://maps.googleapis.com/maps/api/geocode/json", {
        params: {
          address: address,
          key: GOOGLE_MAPS_API_KEY,
        },
      });

      response.json(geocodeResponse.data);
    } catch (error) {
      console.error("Geocode proxy error:", error);
      response.status(500).json({
        error: error.message,
        status: "error",
      });
    }
  });
});
