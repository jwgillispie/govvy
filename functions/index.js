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


      // API key stored in environment variables directly for v2 functions
      const CICERO_API_KEY = process.env.CICERO_API_KEY;


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
      const ciceroResponse = await axios.get(
          "https://cicero.azavea.com/v3.1/official",
          {params},
      );

      // Return the data
      response.json(ciceroResponse.data);
    } catch (error) {
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


      // Access API key directly from environment variables
      const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;


      if (!GOOGLE_MAPS_API_KEY) {
        throw new Error("Google Maps API key not configured");
      }

      // Get additional query parameters for US-only restriction
      const components = request.query.components;
      
      const geocodeParams = {
        address: address,
        key: GOOGLE_MAPS_API_KEY,
        // Add US-only restrictions
        region: 'us',
      };
      
      // Add components filter if provided (e.g., 'country:US')
      if (components) {
        geocodeParams.components = components;
      } else {
        // Default to US-only if no components specified
        geocodeParams.components = 'country:US';
      }

      const geocodeResponse = await axios.get(
          "https://maps.googleapis.com/maps/api/geocode/json",
          {
            params: geocodeParams,
          },
      );

      response.json(geocodeResponse.data);
    } catch (error) {
      response.status(500).json({
        error: error.message,
        status: "error",
      });
    }
  });
});
