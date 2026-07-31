import { Request, Response } from "express";
import axios from "axios";

const PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || "";

export async function autocomplete(req: Request, res: Response): Promise<any> {
  try {
    const input = (req.query.input as string) || "";
    if (!input.trim()) {
      return res
        .status(200)
        .json({ status: true, message: "Empty input.", data: { predictions: [] } });
    }
    if (!PLACES_API_KEY) {
      return res.status(200).json({
        status: true,
        message: "Places autocomplete is not configured yet.",
        data: { predictions: [] },
      });
    }

    const response = await axios.get(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json",
      {
        params: {
          input,
          types: "address",
          key: PLACES_API_KEY,
        },
      }
    );

    const predictions = (response.data?.predictions || []).map((p: any) => ({
      placeId: p.place_id,
      description: p.description,
    }));

    return res.status(200).json({
      status: true,
      message: "Get Address Predictions Successfully.",
      data: { predictions },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function placeDetails(req: Request, res: Response): Promise<any> {
  try {
    const placeId = (req.query.placeId as string) || "";
    if (!placeId.trim()) {
      return res
        .status(400)
        .json({ status: false, message: "placeId is required." });
    }
    if (!PLACES_API_KEY) {
      return res.status(400).json({
        status: false,
        message: "Places lookup is not configured yet.",
      });
    }

    const response = await axios.get(
      "https://maps.googleapis.com/maps/api/place/details/json",
      {
        params: {
          place_id: placeId,
          fields: "address_component,geometry,formatted_address",
          key: PLACES_API_KEY,
        },
      }
    );

    const result = response.data?.result;
    if (!result) {
      return res
        .status(400)
        .json({ status: false, message: "Place not found." });
    }

    const components: any[] = result.address_components || [];
    const getComponent = (type: string) =>
      components.find((c: any) => (c.types || []).includes(type))?.long_name ||
      "";

    const data = {
      address: result.formatted_address || "",
      city: getComponent("locality"),
      state: getComponent("administrative_area_level_1"),
      zipcode: getComponent("postal_code"),
      country: getComponent("country"),
      lat: result.geometry?.location?.lat ?? null,
      lng: result.geometry?.location?.lng ?? null,
    };

    return res.status(200).json({
      status: true,
      message: "Get Place Details Successfully.",
      data,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
