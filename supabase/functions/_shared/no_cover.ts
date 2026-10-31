// "No cover" day off (013 research D10, 003 FR-016). A rider may take the day
// off, free, only when the leg's ride exists and has no driver: the backup
// search found nobody. Mirror of the check in FakeDailyCommuteRepository
// (chooseNoCoverOption → AbsenceKind.noCover, always free).
export interface RideDriver {
  driver_id: string | null;
}

export function canChooseNoCover(ride: RideDriver | null): boolean {
  return ride !== null && ride.driver_id === null;
}
