export interface TruckModel {
  id:                      number;
  company_id:              null | string;
  parking_fees:            null | string;
  trailer_present:         TrailerPresent;
  number:                  string;
  year:                    number;
  make:                    string;
  model:                   string;
  vin:                     string;
  license_plate_number:    string;
  state:                   State;
  status:                  number;
  current_position:        CurrentPosition | null;
  ready_status:            string;
  assgin_vehicle_entry_id: null;
  assgin_status:           string;
  deleted_at:              Date | null;
  created_at:              Date;
  updated_at:              Date;
}

export enum CurrentPosition {
  Departed = "departed",
  InYard = "in_yard",
}

export enum State {
  Al = "AL",
  CA = "CA",
  Ma = "MA",
  Md = "MD",
}

export enum TrailerPresent {
  No = "No",
  Yes = "Yes",
}
