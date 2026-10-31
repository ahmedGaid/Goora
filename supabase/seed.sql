-- Goora demo seed (013 research D13). All people, e-mails, phones and
-- places are FICTIONAL; generated from the app's own demo seeds
-- (CorridorSeed, CairoIsmailiaSeed) on 2026-10-31 so rows match the
-- JSON the app reads. Idempotent: every insert is `on conflict do nothing`.
-- Seeded people have no password: they cannot sign in; sign up as yourself
-- and join a seeded group.

-- People ---------------------------------------------------------------
insert into auth.users (id, email, aud, role) select id, email, 'authenticated', 'authenticated' from (values
  (md5('goora-seed:member:sz-0725/ahmed')::uuid, 'sz-0725.ahmed@seed.goora.test'),
  (md5('goora-seed:member:sz-0725/mohamed')::uuid, 'sz-0725.mohamed@seed.goora.test'),
  (md5('goora-seed:member:sz-0725/sara')::uuid, 'sz-0725.sara@seed.goora.test'),
  (md5('goora-seed:member:sz-0725/youssef')::uuid, 'sz-0725.youssef@seed.goora.test'),
  (md5('goora-seed:member:sz-0740/sara-d')::uuid, 'sz-0740.sara-d@seed.goora.test'),
  (md5('goora-seed:member:sz-0740/nour')::uuid, 'sz-0740.nour@seed.goora.test'),
  (md5('goora-seed:member:sz-0715/youssef-d')::uuid, 'sz-0715.youssef-d@seed.goora.test'),
  (md5('goora-seed:member:sz-0715/karim')::uuid, 'sz-0715.karim@seed.goora.test'),
  (md5('goora-seed:member:sz-0720/hassan')::uuid, 'sz-0720.hassan@seed.goora.test'),
  (md5('goora-seed:member:sz-0720/mona')::uuid, 'sz-0720.mona@seed.goora.test'),
  (md5('goora-seed:member:oct-0700/mohamed')::uuid, 'oct-0700.mohamed@seed.goora.test'),
  (md5('goora-seed:member:oct-0700/youssef')::uuid, 'oct-0700.youssef@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0630/hany')::uuid, 'ci-nc-0630.hany@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0630/mazen')::uuid, 'ci-nc-0630.mazen@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0630/dina')::uuid, 'ci-nc-0630.dina@seed.goora.test'),
  (md5('goora-seed:member:ci-heli-0700/rania')::uuid, 'ci-heli-0700.rania@seed.goora.test'),
  (md5('goora-seed:member:ci-heli-0700/yara')::uuid, 'ci-heli-0700.yara@seed.goora.test'),
  (md5('goora-seed:member:ci-obour-0715/adel')::uuid, 'ci-obour-0715.adel@seed.goora.test'),
  (md5('goora-seed:member:ci-obour-0715/tamer')::uuid, 'ci-obour-0715.tamer@seed.goora.test'),
  (md5('goora-seed:member:ci-obour-0715/lamia')::uuid, 'ci-obour-0715.lamia@seed.goora.test'),
  (md5('goora-seed:member:ci-obour-0715/walid')::uuid, 'ci-obour-0715.walid@seed.goora.test'),
  (md5('goora-seed:member:ci-10r-0730/sherif')::uuid, 'ci-10r-0730.sherif@seed.goora.test'),
  (md5('goora-seed:member:ci-10r-0730/hoda')::uuid, 'ci-10r-0730.hoda@seed.goora.test'),
  (md5('goora-seed:member:ci-nasr-0630/essam')::uuid, 'ci-nasr-0630.essam@seed.goora.test'),
  (md5('goora-seed:member:ci-nasr-0630/nabil')::uuid, 'ci-nasr-0630.nabil@seed.goora.test'),
  (md5('goora-seed:member:ci-nasr-0630/salwa')::uuid, 'ci-nasr-0630.salwa@seed.goora.test'),
  (md5('goora-seed:member:ci-heli-0700-r/mervat')::uuid, 'ci-heli-0700-r.mervat@seed.goora.test'),
  (md5('goora-seed:member:ci-heli-0700-r/nesma')::uuid, 'ci-heli-0700-r.nesma@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0715/magdy')::uuid, 'ci-nc-0715.magdy@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0715/ramy')::uuid, 'ci-nc-0715.ramy@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0715/shaimaa')::uuid, 'ci-nc-0715.shaimaa@seed.goora.test'),
  (md5('goora-seed:member:ci-nc-0715/fady')::uuid, 'ci-nc-0715.fady@seed.goora.test'),
  (md5('goora-seed:member:ci-nasr-0730/ashraf')::uuid, 'ci-nasr-0730.ashraf@seed.goora.test'),
  (md5('goora-seed:member:ci-nasr-0730/manar')::uuid, 'ci-nasr-0730.manar@seed.goora.test')
) as v(id, email) on conflict do nothing;

insert into public.profiles (id, first_name, last_name, gender, role, company, compound, rating,
                             reliability, phone, rider_id_status, driver_docs, privacy_preference) values
  (md5('goora-seed:member:sz-0725/ahmed')::uuid, 'Ahmed', 'M.', 'male', 'driver', null, null, 4.9, 97.0, '+201000000001', 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0725/mohamed')::uuid, 'Mohamed', 'H.', 'male', 'driver', null, null, 4.8, 96.0, '+201000000002', 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0725/sara')::uuid, 'Sara', 'R.', 'female', 'rider', null, null, 5.0, 98.0, '+201000000003', 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0725/youssef')::uuid, 'Youssef', 'S.', 'male', 'rider', null, null, 4.7, 94.0, '+201000000004', 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0740/sara-d')::uuid, 'Sara', 'R.', 'female', 'driver', null, null, 4.9, 99.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0740/nour')::uuid, 'Nour', 'R.', 'female', 'rider', null, null, 4.8, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0715/youssef-d')::uuid, 'Youssef', 'S.', 'male', 'driver', null, null, 4.7, 93.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0715/karim')::uuid, 'Karim', 'R.', 'male', 'rider', null, null, 4.6, 92.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0720/hassan')::uuid, 'Hassan', 'S.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:sz-0720/mona')::uuid, 'Mona', 'N.', 'female', 'rider', null, null, 4.9, 97.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:oct-0700/mohamed')::uuid, 'Mohamed', 'H.', 'male', 'driver', null, null, 4.8, 96.0, '+201000000002', 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:oct-0700/youssef')::uuid, 'Youssef', 'S.', 'male', 'rider', null, null, 4.7, 94.0, '+201000000004', 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0630/hany')::uuid, 'Hany', 'N.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0630/mazen')::uuid, 'Mazen', 'Z.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0630/dina')::uuid, 'Dina', 'N.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-heli-0700/rania')::uuid, 'Rania', 'N.', 'female', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-heli-0700/yara')::uuid, 'Yara', 'R.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-obour-0715/adel')::uuid, 'Adel', 'D.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-obour-0715/tamer')::uuid, 'Tamer', 'M.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-obour-0715/lamia')::uuid, 'Lamia', 'M.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-obour-0715/walid')::uuid, 'Walid', 'L.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-10r-0730/sherif')::uuid, 'Sherif', 'H.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-10r-0730/hoda')::uuid, 'Hoda', 'D.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nasr-0630/essam')::uuid, 'Essam', 'S.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nasr-0630/nabil')::uuid, 'Nabil', 'B.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nasr-0630/salwa')::uuid, 'Salwa', 'W.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-heli-0700-r/mervat')::uuid, 'Mervat', 'V.', 'female', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-heli-0700-r/nesma')::uuid, 'Nesma', 'S.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0715/magdy')::uuid, 'Magdy', 'G.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0715/ramy')::uuid, 'Ramy', 'M.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0715/shaimaa')::uuid, 'Shaimaa', 'M.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nc-0715/fady')::uuid, 'Fady', 'D.', 'male', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nasr-0730/ashraf')::uuid, 'Ashraf', 'S.', 'male', 'driver', null, null, 4.8, 96.0, null, 'notVerified', 'verified', 'verifiedUsers'),
  (md5('goora-seed:member:ci-nasr-0730/manar')::uuid, 'Manar', 'N.', 'female', 'rider', null, null, 4.7, 95.0, null, 'verified', 'notNeeded', 'verifiedUsers')
on conflict do nothing;

-- Groups, pickup points, members -------------------------------------------
insert into public.groups (id, origin_area, destination_area, destination, going, return_time, days, price,
                           detour_minutes, women_only, same_company_only, same_compound_only,
                           rotation_start, arrival, card) values
  (md5('goora-seed:group:sz-0725')::uuid, 'sheikhZayed', 'smartVillage', extensions.st_setsrid(extensions.st_makepoint(31.017, 30.0719), 4326)::extensions.geography, '07:25', '17:00', array['sun', 'mon', 'tue', 'wed', 'thu'], 40, 6, false, null, null, '2026-10-04', '08:05', ('{"destinationPoint":{"lat":30.0719,"lng":31.017},"pickupPoints":[{"lat":30.0427,"lng":30.98}],"going":445,"ret":1020,"days":["sun","mon","tue","wed","thu"],"price":40,"freeSeatsGoing":1,"freeSeatsReturn":1,"tripCost":160,"riderSeats":3,"detourMinutes":6,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:sz-0725:main-gate')::uuid::text || '","name":"mainGate","point":{"lat":30.0427,"lng":30.98},"time":440},{"id":"' || md5('goora-seed:pp:sz-0725:central-st')::uuid::text || '","name":"centralSt","point":{"lat":30.0405,"lng":30.9805},"time":445}],"arrival":485,"arrivalName":"smartVillageGate2","rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:sz-0740')::uuid, 'sheikhZayed', 'smartVillage', extensions.st_setsrid(extensions.st_makepoint(31.017, 30.075), 4326)::extensions.geography, '07:40', '17:05', array['sun', 'mon', 'tue', 'wed', 'thu'], 40, 4, false, null, null, '2026-10-04', '08:20', ('{"destinationPoint":{"lat":30.075,"lng":31.017},"pickupPoints":[{"lat":30.0472,"lng":30.98}],"going":460,"ret":1025,"days":["sun","mon","tue","wed","thu"],"price":40,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":160,"riderSeats":3,"detourMinutes":4,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:sz-0740:stop-1')::uuid::text || '","name":"gasStation","point":{"lat":30.0472,"lng":30.98},"time":460}],"arrival":500,"arrivalName":"smartVillageGate2","rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:sz-0715')::uuid, 'sheikhZayed', 'smartVillage', extensions.st_setsrid(extensions.st_makepoint(31.017, 30.0719), 4326)::extensions.geography, '07:15', '17:20', array['sun', 'mon', 'tue', 'wed', 'thu'], 40, 8, false, null, null, '2026-10-04', '07:55', ('{"destinationPoint":{"lat":30.0719,"lng":31.017},"pickupPoints":[{"lat":30.0463,"lng":30.98}],"going":435,"ret":1040,"days":["sun","mon","tue","wed","thu"],"price":40,"freeSeatsGoing":1,"freeSeatsReturn":1,"tripCost":160,"riderSeats":3,"detourMinutes":8,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:sz-0715:stop-1')::uuid::text || '","name":"gasStation","point":{"lat":30.0463,"lng":30.98},"time":435}],"arrival":475,"arrivalName":"smartVillageGate2","rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:sz-0720')::uuid, 'sheikhZayed', 'smartVillage', extensions.st_setsrid(extensions.st_makepoint(31.017, 30.0719), 4326)::extensions.geography, '07:20', '17:10', array['sun', 'mon', 'tue', 'wed', 'thu'], 40, 5, false, null, null, '2026-10-04', '08:00', ('{"destinationPoint":{"lat":30.0719,"lng":31.017},"pickupPoints":[{"lat":30.0436,"lng":30.98}],"going":440,"ret":1030,"days":["sun","mon","tue","wed","thu"],"price":40,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":160,"riderSeats":3,"detourMinutes":5,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:sz-0720:stop-1')::uuid::text || '","name":"gasStation","point":{"lat":30.0436,"lng":30.98},"time":440}],"arrival":480,"arrivalName":"smartVillageGate2","rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:oct-0700')::uuid, 'october', 'smartVillage', extensions.st_setsrid(extensions.st_makepoint(31.017, 30.0719), 4326)::extensions.geography, '07:00', '16:45', array['sun', 'mon', 'tue', 'wed', 'thu'], 40, 7, false, null, null, '2026-10-04', '07:50', ('{"destinationPoint":{"lat":30.0719,"lng":31.017},"pickupPoints":[{"lat":29.9727,"lng":30.94}],"going":420,"ret":1005,"days":["sun","mon","tue","wed","thu"],"price":40,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":160,"riderSeats":3,"detourMinutes":7,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:oct-0700:stop-1')::uuid::text || '","name":"gasStation","point":{"lat":29.9727,"lng":30.94},"time":420}],"arrival":470,"arrivalName":"smartVillageGate2","rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-nc-0630')::uuid, 'newCairo', 'ismailia', extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, '06:30', '16:30', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 5, false, null, null, '2026-10-04', '08:15', ('{"destinationPoint":{"lat":30.6074,"lng":32.2801},"pickupPoints":[{"lat":30.0313,"lng":31.4787}],"going":390,"ret":990,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":1,"freeSeatsReturn":1,"tripCost":300,"riderSeats":3,"detourMinutes":5,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-nc-0630:stop-1')::uuid::text || '","name":"newCairoMeet","point":{"lat":30.0313,"lng":31.4787},"time":390}],"arrival":495,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-heli-0700')::uuid, 'heliopolis', 'ismailia', extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, '07:00', '17:00', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 4, true, null, null, '2026-10-04', '08:45', ('{"destinationPoint":{"lat":30.6074,"lng":32.2801},"pickupPoints":[{"lat":30.0936,"lng":31.329}],"going":420,"ret":1020,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":300,"riderSeats":3,"detourMinutes":4,"womenOnly":true,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-heli-0700:stop-1')::uuid::text || '","name":"heliopolisMeet","point":{"lat":30.0936,"lng":31.329},"time":420}],"arrival":525,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-obour-0715')::uuid, 'obour', 'ismailia', extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, '07:15', '17:15', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 6, false, null, null, '2026-10-04', '08:45', ('{"destinationPoint":{"lat":30.6074,"lng":32.2801},"pickupPoints":[{"lat":30.1944,"lng":31.454}],"going":435,"ret":1035,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":0,"freeSeatsReturn":0,"tripCost":300,"riderSeats":3,"detourMinutes":6,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-obour-0715:stop-1')::uuid::text || '","name":"obourMeet","point":{"lat":30.1944,"lng":31.454},"time":435}],"arrival":525,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-10r-0730')::uuid, 'tenthOfRamadan', 'ismailia', extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, '07:30', '17:30', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 7, false, null, null, '2026-10-04', '09:00', ('{"destinationPoint":{"lat":30.6074,"lng":32.2801},"pickupPoints":[{"lat":30.2935,"lng":31.7523}],"going":450,"ret":1050,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":300,"riderSeats":3,"detourMinutes":7,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-10r-0730:stop-1')::uuid::text || '","name":"tenthOfRamadanMeet","point":{"lat":30.2935,"lng":31.7523},"time":450}],"arrival":540,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-nasr-0630')::uuid, 'ismailia', 'nasrCity', extensions.st_setsrid(extensions.st_makepoint(31.3457, 30.0551), 4326)::extensions.geography, '06:30', '16:30', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 5, false, null, null, '2026-10-04', '08:15', ('{"destinationPoint":{"lat":30.0551,"lng":31.3457},"pickupPoints":[{"lat":30.6074,"lng":32.2801}],"going":390,"ret":990,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":1,"freeSeatsReturn":1,"tripCost":300,"riderSeats":3,"detourMinutes":5,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-nasr-0630:stop-1')::uuid::text || '","name":"ismailiaMeet","point":{"lat":30.6074,"lng":32.2801},"time":390}],"arrival":495,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-heli-0700-r')::uuid, 'ismailia', 'heliopolis', extensions.st_setsrid(extensions.st_makepoint(31.329, 30.0936), 4326)::extensions.geography, '07:00', '17:00', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 4, true, null, null, '2026-10-04', '08:45', ('{"destinationPoint":{"lat":30.0936,"lng":31.329},"pickupPoints":[{"lat":30.6074,"lng":32.2801}],"going":420,"ret":1020,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":300,"riderSeats":3,"detourMinutes":4,"womenOnly":true,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-heli-0700-r:stop-1')::uuid::text || '","name":"ismailiaMeet","point":{"lat":30.6074,"lng":32.2801},"time":420}],"arrival":525,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-nc-0715')::uuid, 'ismailia', 'newCairo', extensions.st_setsrid(extensions.st_makepoint(31.4787, 30.0313), 4326)::extensions.geography, '07:15', '17:15', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 6, false, null, null, '2026-10-04', '09:00', ('{"destinationPoint":{"lat":30.0313,"lng":31.4787},"pickupPoints":[{"lat":30.6074,"lng":32.2801}],"going":435,"ret":1035,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":0,"freeSeatsReturn":0,"tripCost":300,"riderSeats":3,"detourMinutes":6,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-nc-0715:stop-1')::uuid::text || '","name":"ismailiaMeet","point":{"lat":30.6074,"lng":32.2801},"time":435}],"arrival":540,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb),
  (md5('goora-seed:group:ci-nasr-0730')::uuid, 'ismailia', 'nasrCity', extensions.st_setsrid(extensions.st_makepoint(31.3457, 30.0551), 4326)::extensions.geography, '07:30', '17:30', array['sun', 'mon', 'tue', 'wed', 'thu'], 76, 8, false, null, null, '2026-10-04', '09:15', ('{"destinationPoint":{"lat":30.0551,"lng":31.3457},"pickupPoints":[{"lat":30.6074,"lng":32.2801}],"going":450,"ret":1050,"days":["sun","mon","tue","wed","thu"],"price":76,"freeSeatsGoing":2,"freeSeatsReturn":2,"tripCost":300,"riderSeats":3,"detourMinutes":8,"womenOnly":false,"sameCompanyOnly":null,"sameCompoundOnly":null,"stops":[{"id":"' || md5('goora-seed:pp:ci-nasr-0730:stop-1')::uuid::text || '","name":"ismailiaMeet","point":{"lat":30.6074,"lng":32.2801},"time":450}],"arrival":555,"arrivalName":null,"rotationStart":"2026-10-04"}')::jsonb)
on conflict do nothing;

insert into public.group_pickup_points (id, group_id, point, label, stop_time, stop_order) values
  (md5('goora-seed:pp:sz-0725:main-gate')::uuid, md5('goora-seed:group:sz-0725')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.98, 30.0427), 4326)::extensions.geography, 'mainGate', '07:20', 0),
  (md5('goora-seed:pp:sz-0725:central-st')::uuid, md5('goora-seed:group:sz-0725')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.9805, 30.0405), 4326)::extensions.geography, 'centralSt', '07:25', 1),
  (md5('goora-seed:pp:sz-0740:stop-1')::uuid, md5('goora-seed:group:sz-0740')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.98, 30.0472), 4326)::extensions.geography, 'gasStation', '07:40', 0),
  (md5('goora-seed:pp:sz-0715:stop-1')::uuid, md5('goora-seed:group:sz-0715')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.98, 30.0463), 4326)::extensions.geography, 'gasStation', '07:15', 0),
  (md5('goora-seed:pp:sz-0720:stop-1')::uuid, md5('goora-seed:group:sz-0720')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.98, 30.0436), 4326)::extensions.geography, 'gasStation', '07:20', 0),
  (md5('goora-seed:pp:oct-0700:stop-1')::uuid, md5('goora-seed:group:oct-0700')::uuid, extensions.st_setsrid(extensions.st_makepoint(30.94, 29.9727), 4326)::extensions.geography, 'gasStation', '07:00', 0),
  (md5('goora-seed:pp:ci-nc-0630:stop-1')::uuid, md5('goora-seed:group:ci-nc-0630')::uuid, extensions.st_setsrid(extensions.st_makepoint(31.4787, 30.0313), 4326)::extensions.geography, 'newCairoMeet', '06:30', 0),
  (md5('goora-seed:pp:ci-heli-0700:stop-1')::uuid, md5('goora-seed:group:ci-heli-0700')::uuid, extensions.st_setsrid(extensions.st_makepoint(31.329, 30.0936), 4326)::extensions.geography, 'heliopolisMeet', '07:00', 0),
  (md5('goora-seed:pp:ci-obour-0715:stop-1')::uuid, md5('goora-seed:group:ci-obour-0715')::uuid, extensions.st_setsrid(extensions.st_makepoint(31.454, 30.1944), 4326)::extensions.geography, 'obourMeet', '07:15', 0),
  (md5('goora-seed:pp:ci-10r-0730:stop-1')::uuid, md5('goora-seed:group:ci-10r-0730')::uuid, extensions.st_setsrid(extensions.st_makepoint(31.7523, 30.2935), 4326)::extensions.geography, 'tenthOfRamadanMeet', '07:30', 0),
  (md5('goora-seed:pp:ci-nasr-0630:stop-1')::uuid, md5('goora-seed:group:ci-nasr-0630')::uuid, extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, 'ismailiaMeet', '06:30', 0),
  (md5('goora-seed:pp:ci-heli-0700-r:stop-1')::uuid, md5('goora-seed:group:ci-heli-0700-r')::uuid, extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, 'ismailiaMeet', '07:00', 0),
  (md5('goora-seed:pp:ci-nc-0715:stop-1')::uuid, md5('goora-seed:group:ci-nc-0715')::uuid, extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, 'ismailiaMeet', '07:15', 0),
  (md5('goora-seed:pp:ci-nasr-0730:stop-1')::uuid, md5('goora-seed:group:ci-nasr-0730')::uuid, extensions.st_setsrid(extensions.st_makepoint(32.2801, 30.6074), 4326)::extensions.geography, 'ismailiaMeet', '07:30', 0)
on conflict do nothing;

insert into public.group_members (group_id, user_id, role, legs, seats, card) values
  (md5('goora-seed:group:sz-0725')::uuid, md5('goora-seed:member:sz-0725/ahmed')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Toyota Corolla","colour":"white"}}'::jsonb),
  (md5('goora-seed:group:sz-0725')::uuid, md5('goora-seed:member:sz-0725/mohamed')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Hyundai Elantra","colour":"silver"}}'::jsonb),
  (md5('goora-seed:group:sz-0725')::uuid, md5('goora-seed:member:sz-0725/sara')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0725')::uuid, md5('goora-seed:member:sz-0725/youssef')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0740')::uuid, md5('goora-seed:member:sz-0740/sara-d')::uuid, 'driver', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0740')::uuid, md5('goora-seed:member:sz-0740/nour')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0715')::uuid, md5('goora-seed:member:sz-0715/youssef-d')::uuid, 'driver', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0715')::uuid, md5('goora-seed:member:sz-0715/karim')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0720')::uuid, md5('goora-seed:member:sz-0720/hassan')::uuid, 'driver', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:sz-0720')::uuid, md5('goora-seed:member:sz-0720/mona')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:oct-0700')::uuid, md5('goora-seed:member:oct-0700/mohamed')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Hyundai Elantra","colour":"silver"}}'::jsonb),
  (md5('goora-seed:group:oct-0700')::uuid, md5('goora-seed:member:oct-0700/youssef')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nc-0630')::uuid, md5('goora-seed:member:ci-nc-0630/hany')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Toyota Corolla","colour":"white"}}'::jsonb),
  (md5('goora-seed:group:ci-nc-0630')::uuid, md5('goora-seed:member:ci-nc-0630/mazen')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nc-0630')::uuid, md5('goora-seed:member:ci-nc-0630/dina')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-heli-0700')::uuid, md5('goora-seed:member:ci-heli-0700/rania')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Hyundai Elantra","colour":"silver"}}'::jsonb),
  (md5('goora-seed:group:ci-heli-0700')::uuid, md5('goora-seed:member:ci-heli-0700/yara')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-obour-0715')::uuid, md5('goora-seed:member:ci-obour-0715/adel')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Kia Cerato","colour":"black"}}'::jsonb),
  (md5('goora-seed:group:ci-obour-0715')::uuid, md5('goora-seed:member:ci-obour-0715/tamer')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-obour-0715')::uuid, md5('goora-seed:member:ci-obour-0715/lamia')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-obour-0715')::uuid, md5('goora-seed:member:ci-obour-0715/walid')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-10r-0730')::uuid, md5('goora-seed:member:ci-10r-0730/sherif')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Nissan Sunny","colour":"grey"}}'::jsonb),
  (md5('goora-seed:group:ci-10r-0730')::uuid, md5('goora-seed:member:ci-10r-0730/hoda')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nasr-0630')::uuid, md5('goora-seed:member:ci-nasr-0630/essam')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Chevrolet Optra","colour":"white"}}'::jsonb),
  (md5('goora-seed:group:ci-nasr-0630')::uuid, md5('goora-seed:member:ci-nasr-0630/nabil')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nasr-0630')::uuid, md5('goora-seed:member:ci-nasr-0630/salwa')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-heli-0700-r')::uuid, md5('goora-seed:member:ci-heli-0700-r/mervat')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Toyota Yaris","colour":"red"}}'::jsonb),
  (md5('goora-seed:group:ci-heli-0700-r')::uuid, md5('goora-seed:member:ci-heli-0700-r/nesma')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nc-0715')::uuid, md5('goora-seed:member:ci-nc-0715/magdy')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Hyundai Accent","colour":"silver"}}'::jsonb),
  (md5('goora-seed:group:ci-nc-0715')::uuid, md5('goora-seed:member:ci-nc-0715/ramy')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nc-0715')::uuid, md5('goora-seed:member:ci-nc-0715/shaimaa')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nc-0715')::uuid, md5('goora-seed:member:ci-nc-0715/fady')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb),
  (md5('goora-seed:group:ci-nasr-0730')::uuid, md5('goora-seed:member:ci-nasr-0730/ashraf')::uuid, 'driver', array['going', 'ret'], 4, '{"vehicle":{"make":"Kia Picanto","colour":"blue"}}'::jsonb),
  (md5('goora-seed:group:ci-nasr-0730')::uuid, md5('goora-seed:member:ci-nasr-0730/manar')::uuid, 'rider', array['going', 'ret'], null, '{}'::jsonb)
on conflict do nothing;


-- A company with enrolled employees (010 R10, 013 D13) --------------------------
-- "Demo Motors", fictional, active, six employees; the first is the HR contact;
-- five said yes to sharing their trips with HR. Employees 2–6 have a commute
-- profile in New Cairo and no group, so the dashboard shows one route gap of 5.
insert into auth.users (id, email, aud, role)
select md5('goora-seed:employee:' || n)::uuid, 'employee' || n || '@seed.goora.test', 'authenticated', 'authenticated'
from generate_series(1, 6) as n
on conflict do nothing;

insert into public.profiles (id, first_name, last_name, gender, role, company, rating, reliability,
                             rider_id_status, work_email, work_email_verified)
select md5('goora-seed:employee:' || n)::uuid,
       (array['Karim', 'Laila', 'Omar', 'Rana', 'Tarek', 'Salma'])[n],
       (array['H.', 'S.', 'F.', 'M.', 'A.', 'N.'])[n],
       (array['male', 'female', 'male', 'female', 'male', 'female'])[n],
       'rider', 'Demo Motors', 4.8, 98, 'verified',
       lower((array['Karim', 'Laila', 'Omar', 'Rana', 'Tarek', 'Salma'])[n]) || '@demomotors.test', true
from generate_series(1, 6) as n
on conflict do nothing;

insert into public.companies (id, name, status, hr_contact_id, contract_start, approved_at, minimum_seats, price_per_seat)
values (md5('goora-seed:company:demo-motors')::uuid, 'Demo Motors', 'active',
        md5('goora-seed:employee:1')::uuid, '2026-10-01', '2026-10-01T09:00:00', 5, 99)
on conflict do nothing;

insert into public.company_domains (domain, company_id)
values ('demomotors.test', md5('goora-seed:company:demo-motors')::uuid)
on conflict do nothing;

insert into public.enrollments (id, company_id, person_id, name, work_email, enrolled_at)
select md5('goora-seed:enrollment:' || n)::uuid, md5('goora-seed:company:demo-motors')::uuid,
       md5('goora-seed:employee:' || n)::uuid,
       (array['Karim', 'Laila', 'Omar', 'Rana', 'Tarek', 'Salma'])[n],
       lower((array['Karim', 'Laila', 'Omar', 'Rana', 'Tarek', 'Salma'])[n]) || '@demomotors.test',
       '2026-10-05T09:00:00'
from generate_series(1, 6) as n
on conflict do nothing;

insert into public.hr_consents (person_id, "on")
select md5('goora-seed:employee:' || n)::uuid, n <= 5 from generate_series(1, 6) as n
on conflict do nothing;

insert into public.commute_profiles (user_id, home, home_area, work, work_area, departure, return_time, days,
                                     home_place, work_place)
select md5('goora-seed:employee:' || n)::uuid,
       extensions.st_setsrid(extensions.st_makepoint(31.47, 30.03), 4326)::extensions.geography, 'newCairo',
       extensions.st_setsrid(extensions.st_makepoint(32.27, 30.60), 4326)::extensions.geography, 'ismailia',
       '06:30', '16:30', array['sun', 'mon', 'tue', 'wed', 'thu'], 'home-nc', 'work-ism'
from generate_series(2, 6) as n
on conflict do nothing;

insert into public.company_log (company_id, at, actor, kind)
select md5('goora-seed:company:demo-motors')::uuid, '2026-10-01T09:00:00', 'goora', 'approved'
where not exists (select 1 from public.company_log where company_id = md5('goora-seed:company:demo-motors')::uuid);
