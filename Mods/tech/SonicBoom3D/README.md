# SonicBoom for DCS World

A vapor cone that forms around your jet as it pushes through the sound barrier, shaped after real transonic photos (an F/A-18F side on): the shock is a flat plane across the flight path at the tail, the vapor's crisp back edge, and ahead of it the vapor fills a straight-sided cone whose point is on the fuselage over the wing root and whose rim reaches past the wingtips.

Updates, bug reports and feedback: [the SonicBoom3D Discord](https://discord.gg/hAy2gTF7R2).

Original mod by Bush_Wookiee_92. Many thanks to him for letting me rebuild it and make it work on most of DCS's airframes.

It's drawn as a real volume, not flat sprites:

- Seen side on, as in photos: a crisp straight line at the tail, crisp straight slanted edges back from the fuselage, and fainter vapor between. The vapor lies mostly on the cone's two faces, a thin disc just ahead of the shock and a thin shell just inside the cone's front, so their edges show where you look along them.
- Head-on it's a halo: clear in the middle, brightest in a ring, fading away past the wingtips.
- The vapor clears at once behind the shock. It looks like condensation: smooth, as in photos, with gentle clumps streaming aft and churning, faint broad fibres running out along the cone, and a rim that wavers and frays. Out at the tips it opens into gaps you see the sky through.
- It thickens and thins as the jet flies through damper and drier patches of air. The patches are fixed in the world and about 500 ft across, so at Mach 1 the change sweeps back through the cone a few times a second, and two jets flying through the same air see the same patches.
- It casts a soft, streaky shadow on whatever it shades from the sun: the ground under your jet and the jet itself. The shadow fades with distance (none past 0.8 nm) and is off at night.
- The jet shades its own vapor: where its wing or fuselage stands between a bit of vapor and the sun, that vapor gets less sunlight (the sky still lights it, and so does the lit vapor round it). Worked out at every step through the vapor from a rough model of the jet, its wing and fuselage from its own measurements, so it holds from any angle and has no grain; missiles and pylons don't cast shade. `JET_SHADE = false` turns it off.
- It reflects in water, the sea, lakes and rivers, the way DCS reflects its jets, so the two go together: DCS's screen-space reflection (`Bazar\shaders\enlight\ssr.hlsl`), run on the vapor as shown. From each water pixel the view ray is bounced off the water and followed a short way across the screen; where it first passes just behind the vapor, that vapor shows. So it sits right under the jet with the jet's own reflection, not a mirror image down in the water, smeared down a little as waves make it; the higher the jet, the further there is to look, so it fades and slides toward where a mirror image would be, and by about 80 ft it's gone (lower seen close up, higher from far off, as DCS's own). Faint looking straight down and stronger at a grazing angle, weighed as DCS weighs reflections in water. Like the vapor itself it's blended over a few frames, found each frame in what was shown the frame before (as DCS finds its own), so it has no grain.
- It reaches further out along the wings than below the jet, and fuller on top of the wing. Pulling G gathers it over the wing, as photos of jets pulling through Mach 1 show: from 1.5 G its bottom draws in, nearly gone by 5.5 G, and its top a tenth. Pushing negative G does the mirror image, gathering it under the wing: from -0.5 G its top draws in, nearly gone by -3 G, and its bottom a tenth. It rolls with the jet.

 It goes into DCS's own HDR picture, after its clouds and effects (and, with DLSS, after the upscale) and before its exposure and tone mapping, and it's lit with DCS's own sun and sky light, the way DCS lights its white smoke, and no brighter (so DCS's tone mapping never clips it to flat white). So DCS's exposure, tone mapping and colours apply to it as to everything else in the picture. Sunlight, and the sky's light, are dimmed by the vapor they pass through on the way in, clumps included, so the side away from the sun is shaded; and its tiny droplets scatter mostly forward, so looking toward the sun it glows. Side on you see into it: it's thick and thin in clumps and streaks, with the jet showing through where it's thin. It flickers and swells a little.

 Its light follows DCS's, as DCS lights its own smoke:

- **Under cloud:** where DCS's cloud shadow keeps the sun off the jet (`Bazar\shaders\deferred\shadows.hlsl`, the 3D cloud-shadow texture DCS binds at t91, looked up where the jet is), the vapor gets no sunlight, only the sky's, so under an overcast it's grey like everything else, and it casts no shadow on ground the clouds already shade.
- **The sky's light** is DCS's ambient cube (the 9 colours DCS lights its smoke with, found by its shape wherever it's bound), or, until that's found, its environment cube (the sky all round the camera, `environmentMap` at t123, at its blurriest): blue on a clear day, grey under a deck, dark at night.
- **At night** DCS lights the world with the moon through the sun's own values (its "sun" sits where the moon is, a few thousandths as bright), so the vapor is moonlit like the jet, and faint on a dark night.
- **The afterburner's glow** lights it: DCS's dynamic point light just behind the nozzles, on the jet's axis (t97). For now its other lights are left out (the anti-collision strobe and the fin's floodlights, spots in DCS; the wingtip nav lights are only glowing sprites, with no light of their own). DCS lists its lights per 8-pixel tile of the screen (t94, t95), culled against what's drawn in each and a spot's to its beam, so the lists change from tile to tile; and per view, for that view's camera, so each picture's vapor is lit from the lists DCS bound while drawing that picture (the last bound can be another view's: a reflection's, the other eye's); the lights are gathered once for each jet: every tile under its vapor marks its lights that can reach the cone (a compute pass, one bit per light), so a light is found from any angle however few tiles DCS lists it for (a tail floodlight reaching 5 m), each once and only those whose values make sense, so the whole of its vapor is lit alike. Each lights it as DCS lights a surface facing it, in its colour, but softened within a metre and capped at twice its light at a tenth of its reach (a surface there is lit at one point; the vapor is a volume all round it), and scattered evenly every way. Worked out every half metre of vapor along each pixel's ray, so a light reaching only a few metres (the tail floodlights) lights the vapor in its beam from any angle; lights that can't reach the vapor are left out (by DCS's falloff a light reaching 1 m, a nav light's glow, lights nothing).

 If DCS's light or its HDR picture can't be found, it's drawn onto the finished picture instead, lit by its own sun for the mission's date, time and map: white at midday, warm at dusk, dim at night.

- **Where you see it:** in outside views, from the cockpit (outside the canopy, behind the canopy frame), and in the cockpit mirrors. The jet, the cockpit and anything else in front hide it, the same way they hide the rest of the world.
- **Who sees it:** only you, on your own jet and on the 25 nearest other jets (AI or human) within 4.3 nm.
- **Where it works:** single player, and as a client on any server that allows own-aircraft export (most do). On other jets in multiplayer, the server must also allow object export. If it doesn't, you still get it on yours.
- **When it shows:** as in real footage, mostly just below the speed of sound: it forms from Mach 0.94, is solid from 0.97 to 1.01, and is gone by 1.03, so going through it shows for a few seconds. Pulling G brings it in earlier, as in real life: at 4 G it forms from 0.88 and is solid from 0.91. While it builds up and while it breaks up it flickers a few times a second, flaring up more of the time the stronger it is, but never goes out: between about half and a bit more than where it has got to. And it grows into its full size: its rim close round the fuselage at first (a third of the way out), reaching further out with each flare, all the way out once it's solid. Once formed it's always there, breathing gently: it swells and shrinks a little a few times a second, its shock moving back and forth with it. It's thickest at low altitude.
- **IC:** everything lives in `Saved Games\DCS` and no DCS file is changed, so the integrity check (IC) passes.
- **A mod DCS knows:** its icon sits on the main menu's bar at the bottom (click it for what it is, and its Set Wallpaper gives the main menu and the loading screen pictures of the cone in DCS), and its settings, quality included, are on its own page under **Options > Special > SonicBoom3D**, changeable in flight too.

## Install

1. Extract `SonicBoom3D-1.3.zip` into `C:\Users\<you>\Saved Games\DCS\` (or add it to OvGME as is). You get:
   - `Mods\tech\SonicBoom3D\`, the mod: `bin\SonicBoom3D.dll`, which draws the cone into DCS's picture, its icon (`Theme`), its settings page (`Options`) and this read-me
   - `Scripts\Hooks\SonicBoom3D.lua`, the hook that feeds your jet and camera to the DLL
2. Restart DCS.
3. Updating from a version before the mod: delete the old `Scripts\SonicBoom` folder; the DLL now lives in the mod.

To check that it's working: the SonicBoom3D icon is on the main menu's bar (it's in alphabetical order; the arrows scroll it), and its page is under Options > Special. Then open `Saved Games\DCS\Logs\dcs.log` and search for `SONICBOOM`:

- `3D cone loaded: present hooked` means the DLL is in.
- `settings from Options > Special: on, quality 3, ...` at the start of each mission means the hook is reading the Special page (`from this file` means it couldn't, and is using the defaults at the top of the hook).
- About 5 seconds into a mission, and every minute after, a status line gives counts:
  - `drawn N (N with depth fading)`: frames drawn with DCS's own camera and depth buffer. If the second number stays 0, the jet and cockpit won't hide the vapor.
  - `N into views, N views missed`: in VR, how often it went into an eye's picture, and how often an eye's picture was skipped because DCS's camera for it wasn't found. Missed views should stay at 0.
  - `clouds' shadow found`, `DCS's lights found (its own view's N times; by your jet: ...)` (N should climb with the vapor drawn; 0 means the last bound lists are used) and `sky from DCS's ambient cube (slot N: average r g b, top r g b)` (or `environment cube`): the cloud shadow, the jets' own lights and the sky's light, as DCS binds them; `DCS's light found (sun ...)` gives its sun's brightness and height (at night, the moon's).
  - `N into HDR pictures with DCS's light` and `DCS's light found`: how often it went into DCS's HDR picture, lit by DCS's light. If the first stays 0, it's being drawn onto the finished picture instead (see above); a frame capture (below) shows why.
  - `eye offset`: how far the last eye was from your head, about 0.03 m in VR and 0 on a flat screen. `most off-centre view` goes above 1 when you've looked far to the side with eye-tracked insets.
  - `placed by DCS's camera N (moved on to its picture's time n), by the hook's M (DCS's origin not known a, cameras apart b; picture's time T, your jet's T)`: how often the vapor was placed against the camera DCS drew the picture with, and how often against the hook's camera instead, and why. N should climb while the vapor shows and M stay near 0: each of those frames may jump by a frame's travel. (A view's camera DCS sends again without the rest of its constants takes DCS's origin from the last that had it, half a second at most.)
  - `mirrors N`: how often it was drawn into the mirrors. This is 0 in outside views, because DCS doesn't render mirrors there.
  - `multisampled (MSAA) in N frames`: DCS's MSAA is on. The vapor goes into its multisampled pictures and mirrors as into any others.
  - `frames shown without the vapor in DCS's view N (in R runs, longest L; C captured)`: frames DCS showed where the vapor didn't go into its picture, though it had before, in how many separate runs, and the longest. For their first 2 seconds those frames get no vapor (rather than vapor placed by the wrong camera), so a run shows as the cone popping out; after that it goes onto the finished picture by the hook's camera, as long as DCS is still drawing a 3D view. The F10 map makes a run too, and gets no vapor. Otherwise this should stay at 0. With **Advanced logging** on, each run also gets its own line as it ends (how many frames, how many of them went onto the finished picture, DCS's picture's time, when DCS last sent its main camera), the first three runs each record the next frame (see Frame capture), and the status line comes every 10 seconds instead of every minute. For a report of the cone jumping or popping out: tick Advanced logging, fly until it happens, and send `dcs.log` and the capture files.
  - `short gaps in the vapor N (in one jet's M)`: N, times all vapor went missing for up to 30 frames between frames with it, for whatever reason (the runs above among them); M, times one jet's cone did while others were still drawn (not counting a cone off screen). With **Advanced logging** on, each gets a line. A gap in all the vapor says what its first frame saw: how old the hook's frame was, your jet's strength and whether it was for the main view, how many jets there were to draw and how many were drawn, too faint or off screen, and whether the vapor went into DCS's view, onto the finished picture or neither. A gap in one jet's cone says why that jet's was missing (not in the hook's frame, not to show, or too faint), with the hook's strength, speed and G for it then and the frame before. For a report of the cone missing a frame.
  - `one jet's cone jumping for a frame N`: times a jet's cone stood more than 1.5 m along its flight path from where its speed and DCS's clock put it, for one frame, and back the next. It should stay at 0. With **Advanced logging** on, each gets a line with how the three frames were timed: DCS's clock for the picture, when the hook saw the jet there (its pose), the simulation step taken as the picture's, and how far the jet was moved on to it. For a report of a cone jumping forward for a frame.
- `bank check: ...` appears the first time you bank in the cockpit: it confirms which way DCS counts bank, so the vapor rolls the right way.
- `the picture is drawn N simulation frame(s) behind Lua` appears if the hook re-measures that from the cockpit. DCS's simulation runs a step ahead of the picture, so in motion the cone is placed where the jet was one frame earlier. The DLL places the cone against the camera DCS drew each picture with (its `gOrigin` and `gCameraPos`), with the jet as the hook saw it in the frame current when DCS drew that picture: timed frame by frame in a chase view, that's where DCS draws it (the hook runs as each frame begins; one running again before the vapor goes in is a step ahead, and isn't used). Only when DCS's clock for that very picture (`gModelTime`) shows the hook's frame a step apart is the jet moved on to it; DCS's clock reads up to a millisecond off, and now and then isn't sent at all.
  - `fov from DCS's camera` means the cone follows zoom. `from the Default FOV setting` means it couldn't find DCS's camera and is using your setting instead. This also shows while the game is paused.

To check the cone lines up without going supersonic, tick **Test mode** on its Special page. The cone then shows at any speed, even parked, at full strength, so it holds steady instead of flashing. Untick it afterwards.

## Updates

As DCS starts, SonicBoom3D asks GitHub whether there's a newer version (its latest release, `KanaiCasual/SonicBoom3D`; nothing about you is sent). If there is, a window says so in the main menu, `1.2 → 1.3`, with a short chime, never over a mission:

- **Update now** downloads it and puts it in place of this one. Restart DCS to use it. Only the mod's own files are written: `Mods\tech\SonicBoom3D` and `Scripts\Hooks\SonicBoom3D.lua` (settings changed at the top of the hook go back to the release's; the Special page's are kept). If it can't, it says why and offers the download page.
- **Release page** opens its page on GitHub in your browser, to download the zip and install it yourself.
- **Skip 1.3** doesn't ask about that version again (kept in `Saved Games\DCS\Config\SonicBoom3D update.lua`; delete it to be asked).
- **Remind later** (or Esc) asks again next time DCS starts.

`dcs.log` has a `SONICBOOM` line with what the check found. `UPDATE_CHECK = false` at the top of the hook turns it off.

## Uninstall

Delete the `Mods\tech\SonicBoom3D` folder and `Scripts\Hooks\SonicBoom3D.lua`.

## Settings

On its page, **Options > Special > SonicBoom3D**. Changes apply straight away, in a mission too (Esc, Options). The version you have is at the top right of the page.

| Setting | Default | Meaning |
|---|---|---|
| Vapor cone | on | The cone at all |
| Quality | High | How fine its steps through the vapor are. With the cone filling a 4K screen on the development PC: Low 1.35 ms, Medium 1.6, High 1.9, Ultra 2.55 |
| Hard to soft cone | 0% | From the crisp cone (0%) to a smooth mist with soft edges, as the JF-17 draws its own vapor (100%); in between, a blend of the two, even along the slider (`SOFTNESS`) |
| Instability | 0% | How unstable the formed cone is, as in footage of jets near Mach 1: parts of it round the jet drop out for a moment (a quarter to half of it), and now and then all of it, coming back within half a second or so. 0% holds it steady once formed; at 100% it's all gone about a sixth of the time. The same for every jet, each with its own timing (`INSTABILITY`) |
| Cone per aircraft | each aircraft's Default | See below |
| The jet shades its vapor from the sun | on | `JET_SHADE` |
| Its shadow | on | Its shadow on the ground, the sea and the jet |
| Its reflection in water | on | As DCS reflects jets |
| From the cockpit / In the cockpit mirrors | on | Where it shows |
| Other jets | The nearest 25 | None, or the nearest 5, 10, 25 or 50 (`OTHER_JETS`) |
| Test mode | off | At any speed and height (`TEST_MODE`) |
| Advanced logging | off | More in `dcs.log` for bug reports, and captures of the first frames the cone misses (`ADVANCED_LOGGING`; see the status line above) |
| Mach readout | off | For bug reports about the cone showing at the wrong speed: a box on screen with each jet's Mach as the cone goes by it, the cone's strength, its airspeed, ground speed, the wind, its altitude and G, four times a second, and every 10 s in `dcs.log` (lines starting `readout:`). It starts at the top left; drag it anywhere by any part of it, and it stays there (`Config\SonicBoom3D readout.lua`). Your jet is listed twice: as DCS has it (which your cone goes by), and worked out from its flight path the way every other jet's is (DCS gives Lua only other jets' positions); if those two disagree, the other jets' Mach is off by as much (`MACH_READOUT`) |

**Cone per aircraft.** Each aircraft has its own cone settings, used for every jet of that type, yours and AI (an AI type that shares a model, like the AI F/A-18C, shares its settings; types not listed share **Other jets**). The page opens on the aircraft you're sitting in, or else the one you picked last. Untick **Vapor cone on this aircraft** and no jet of that type gets a cone, yours or AI, whatever its preset (its presets are kept, greyed out, till you tick it again); an AI one switched off doesn't count among the nearest **Other jets** either.

| Setting | Default | Meaning |
|---|---|---|
| Move cone forward | 0 ft | The whole cone moves forward along the jet, or back below 0 (±25 ft) |
| Front forward | 0 ft | Its point reaches further forward: a longer cone, or a shorter one below 0 (±25 ft) |
| Width | 100% | How far out the cone's rim reaches: 100% is 1.2 half-spans, as in photos (`CONE_WIDTH` times this) |
| Height above / below | 100% | How far up and down it reaches, against how far out to the sides: 100% is as round as before (25 to 200%). G draws in what's set here: pulling, the bottom nearly all and the top a little; pushing, the other way round |
| Thickness | 100% | How thick the vapor looks (100% is `DENSITY` 2 below) |
| Flashing and breathing | 100% | How much it flashes forming and breaking up, and breathes (`PULSE` times this); 0% is steady |

**Default** is each aircraft's built-in setting and is never changed: moving a slider while it's in use starts a preset of that aircraft's own, **Custom**. Type a name and **Save as new preset** to keep the settings shown under that name; pick a preset to use it, **Delete** to remove the one shown, **Reset** to go back to Default (your presets stay). The preset picked for an aircraft is the one it flies with. They're saved with DCS's other settings when you press OK (Cancel undoes them), in `Saved Games\DCS\Config\options.lua`.

The rest are at the top of `Scripts\Hooks\SonicBoom3D.lua`; restart DCS after changing them. Those marked `page` there are what the page starts at, and once it's been saved (OK in Options) the page's values are used instead.

| Setting | Default | Meaning |
|---|---|---|
| `MACH_ON_START` / `MACH_ON_FULL` | 0.94 / 0.97 | Where the vapor starts flashing in, and where it's solid |
| `MACH_OFF_START` / `MACH_OFF_END` | 1.01 / 1.03 | Where it starts breaking up, and where it's gone |
| `G_EARLIER` | 0.02 | G brings it in earlier, pulling or pushing: this much Mach per G beyond 1 either way (-3 G as 3 G), up to 4 G's worth. 0 is the same at any G |
| `ALT_FULL_FT` / `ALT_FADE_FT` / `ALT_MIN` | 10000 / 40000 / 0.15 | Full thickness below 10,000 ft, thinning to 15% by 40,000 ft, where the air is dry. Higher up it's thinner, not flashing |
| `CONE_WIDTH` | 1 | How far out the cone's rim reaches: 1 is 1.2 half-spans, as in photos; 0.85 is 15% narrower, 1.2 wider. Where it starts and ends stays put: its angle follows. Each aircraft's Width on the page scales it |
| `JET_SHADE` | true | The jet's wing and fuselage shade its vapor from the sun |
| `DENSITY` | 2 | How thick the vapor looks: 1 is thinner and more see-through, 4 is twice as thick. Each aircraft's Thickness on the page scales it |
| `PULSE` | 1 | How much it flashes while forming and breaking up, and breathes once solid: 0 is steady (a plain fade), 1 is like real footage, up to 1.5. Each aircraft's Flashing on the page scales it |
| `INSTABILITY` | 0 | How unstable the formed vapor is, 0 to 1 (the page's Instability, in percent) |
| `SHOW_IN_COCKPIT` | true | Draw it in the cockpit view |
| `COCKPIT_RADIUS_FT` | 26 | Camera within this many feet of your jet counts as cockpit view |
| `SHOW_IN_MIRRORS` | true | Draw it in the cockpit mirrors |
| `MIRROR_BRIGHTNESS` | 1 | How bright it is in the mirrors (see Limits) |
| `MAX_DISTANCE_NM` | 1.6 | No cone when the camera is further away than this, in nautical miles |
| `OTHER_JETS` | 25 | Vapor on this many of the nearest other jets too. 0 is your jet only |
| `OTHER_DISTANCE_NM` | 4.3 | ...within this many nautical miles of the camera |
| `DCS_LIGHT` | true | Draw it into DCS's own HDR picture, lit with DCS's light. `false` draws it onto the finished picture with its own light, as before |
| `SCATTER_TEST` | false | A test of fuller lighting, regardless of cost: half-length steps, a 12-step march toward the sun right across the cone through all the vapor's detail, light scattered several times over, and the sky's light shaded by the vapor above. About 5 to 7 times the GPU time (6.4 ms with the cone filling a 4K screen, 8.5 ms at 25 m); not for VR |
| `TEST_MODE` | false | Show the cone at any speed and height |
| `ADVANCED_LOGGING` | false | More in `dcs.log` for bug reports: a status line every 10 s, a line per run of frames shown without the vapor in DCS's picture and per short gap in the vapor, the first three runs captured |
| `MACH_READOUT` | false | The Mach readout, on screen and in `dcs.log` (see Settings) |
| `UPDATE_CHECK` | true | Ask GitHub for a newer version as DCS starts (see Updates) |

Each jet's cone is placed and sized from its own shape (in `Mods\tech\SonicBoom3D\jets.lua`, which the page shares), taken from DCS's aircraft files (`CoreMods\aircraft`) and measured in DCS:

- **How it was checked against the real thing.** Side-on photos of real vapor cones (Wikimedia Commons, DVIDS and airshow photos), measured against each airframe:

  | Type | Photos | Solid shock (back edge) | Cone point | Rim (half-spans) |
  |---|---|---|---|---|
  | F/A-18C | 6 | 0.98 to 1.05 of the length: at or just behind the nozzles (-8.6 m) | 0.66 (-2.1 m) | 1.25 to 1.7 |
  | F/A-18E/F | 8 | 0.94 to 0.95: the nozzles; forming 0.77 to 0.85 | 0.61; forming on the LEX | 1.55 to 1.72; forming 0.6 to 0.9 |
  | F-15E, F-15C | 3 | about 0.97: the nozzles, fins inside the vapor | 0.26 to 0.40: behind the canopy | 1.1 to 1.4, mostly above |
  | F-16 | 4 | weak at the wing's trailing edge, full at the tail | 0.60 | 1.0 to 1.2 |
  | F-14 | 4 | 0.73 to 0.88 forming, 1.12 full | 0.62 | 0.4 to 0.7, 2.2 full |
  | F-4 | 2 | at its wing's trailing edge and nozzles (-4.8 m); its tail behind | 0.55 | 1.0 |
  | MiG-29 | 1 | at its wing's trailing edge (-4.0 m) | 0.74 | 1.0 or more |
  | F-22, F-35 (for the trend) | 4 | 0.80 to 1.02: the tail | 0.5 to 0.74 | 0.5 to 1.5 |

  None usable were found for the Su-27 family, F-5, MiG-21, Mirages, Tornado, Harrier, Viggen or JF-17; they follow the rule. And the physics: a slender-body model of a Hornet-sized jet (the transonic area rule, small-disturbance theory with the Prandtl-Glauert stretch) with water condensing where the expanding air cools below its dew point. The vapor fills the supersonic pocket, its front the sonic line, its back the shock; how far out it reaches grows as 1 / sqrt(1 - M²) (1.2 half-spans at Mach 0.94, 1.9 at 0.97, 3.3 at 0.99 in damp air), and humidity decides how much of the pocket condenses (from local Mach 1.00 at 85%, 1.08 at 55%; none at 40%).
- **The `GEOMETRY` table** lists, per aircraft type, the pilot's seat, the wingtip, where the wing ends (`te`: its trailing edge at the fuselage, or the tips when they're swept back), where it begins (`le`: its leading edge at the fuselage, or a swing-wing's glove; not the strakes or canards ahead of it) and the engine nozzles (metres ahead of the model's origin), plus the wingspan and length.
  - `te`, `le`, and the whole shape of the AI-only jets, were measured from straight-down views of each model in DCS, scaled and aligned against the model's box as DCS's mission scripting reports it.
  - The shock, the cone's flat back, stands at the wing's trailing edge where it meets the fuselage (`te`; the nozzles for a jet with none listed) once the vapor is solid, crossing the tips about halfway along them. Photos put the solid shock further back, by the nozzles (the table above), but drawn there the cones look too far back in DCS. While the vapor forms it's about halfway forward to the wing root: it moves back as the vapor strengthens.
  - The cone starts, its point on the fuselage, 40% of the way back from `le` to `te`: where the air over the wing goes supersonic (the F/A-18C's photos put it at -2.1 m; this gives -2.47). The F-15's photos put it further forward, behind the canopy, but drawn there its cone reached too far forward; it follows the rule too. A jet with no `le` starts where a 60° cone 1.45 half-spans across would.
  - The cone's rim, at the shock, reaches 1.2 times the half-span (a little further along the wings, less below), times `CONE_WIDTH`, as most photos (1.0 to 1.4 half-spans). Its front runs straight from the rim to its start, so the angle follows from the jet.
  - While the vapor forms and breathes, the whole cone moves with the shock.
  - Its other proportions (how deep the cone's faces are, the vapor's grain) come from the span and length, with the F-15 as 1. The F-16 comes out at 0.74.
- **Jets without a readable file** use a sister airframe's shape: the F-15C, Su-27, Su-33 and the Flaming Cliffs MiG-29s. Their seat is measured from the cockpit camera once you've been in the cockpit (F1) in that mission. Types not listed at all are treated as a mid-sized fighter, measured the same way.
- **AI-only jets** have their own measured shapes: the AI F-16s, F-5E, Mirage 2000-5, Tornado, MiG-23, MiG-25, MiG-27, MiG-31, Su-17, Su-24, Su-30, Su-34, B-1B, Tu-160 and Tu-22M3. Swing-wings are measured swept back, as at speed. The `SAME_AS` table sends other names for the same model (F-16C bl.50, F/A-18A, QF-4E, Tornado GR4 and so on) to one shape.
- **The `OWN_VAPOR` list** names jets whose module draws its own vapor cone: the JF-17 and the Mirage 2000C. When a person flies one, it gets no cone from this mod; an AI one (its module isn't running, so it has no vapor of its own) gets this cone. Delete a line to get this cone on that jet always.

`build\placement_chart.png` shows every jet's cone to scale against its seat, wingtips and nozzle.

## Limits

- **Reflections: where DCS marks water.** Water is found by the marks DCS puts in its stencil buffer for each pixel (`Bazar\shaders\common\stencil.hlsl`); with DLSS they're read from the depth buffer at the render size, before the upscale. Where no marks can be read, only the sea reflects it, found by being at sea level, and flat land right at sea level (a beach, a harbour) does too. The jet's own reflection doesn't hide the vapor's.
- **Labels and menus.** The cone goes into DCS's picture before DCS draws its interface, so labels and menus sit on top of it. If DCS's camera can't be found, it falls back to drawing over the finished screen, menus included.
- **GPU cost.** On the development PC, at High: about 1.9 ms per picture at 3840×2160 with the cone filling the screen, and at a typical 25 m, shadow included (Low 1.35 ms, Ultra 2.55 ms filling the screen). VR draws each eye's views separately, so it costs up to that per view. Video memory: each view keeps two half-float pictures of its own size for the reprojection (about 130 MB at 4K), and they share two as big as the biggest view.
- **Mirror brightness without DCS's light.** When DCS's light is found the mirrors use it too. Otherwise the vapor there has a fixed brightness, set to match a sunlit cloud, and at dusk or night it may look too bright in the mirrors; lower `MIRROR_BRIGHTNESS`.
- **MSAA edges.** With DCS's MSAA the vapor is worked out once per pixel, from each pixel's first depth sample, so where it meets the jet's outline its edge isn't smoothed the way DCS's own edges are.
- **Placement checked in DCS on a 46-jet lineup** (`SonicBoom Mach 1 lineup.miz`: every supersonic type, at Mach 1). The mirror detection looks for DCS's mirror camera near your head, which should hold for other jets; the F-14's and F-15E's mirrors have been checked. The F-14 draws its mirror with a camera of the mirror picture's own shape (square), found as a wide camera by your head looking back along the jet with a nearer clip than your view's.
- **VR is new.** It's drawn into each eye's own picture, from that eye's position, including the sharp eye-tracked insets of Quad-Views-Foveated. Confirmed in a headset (SteamVR OpenXR with eye-tracked Quad-Views-Foveated), including looking back over your shoulder from the cockpit. Other VR setups haven't been tried.
- **Other jets: speed and G are worked out.** DCS tells mods only where other jets are and which way they point, not their speed, Mach or G (Tacview works the same way). So their speed and G come from their flight path, smoothed over a few tenths of a second. Their Mach is that speed less the wind where they are, over the speed of sound at their height, with the mission's temperature read off your own jet's Mach meter. Expect their vapor to start or stop a little later than on your jet, and to be off by about 0.01 Mach if you're spectating, or if the mission's temperature changes with height differently from the standard atmosphere. Each other jet costs GPU time for what its vapor covers on screen: nothing off screen, little far away.
- **Other jets: placement from their type.** A type in `GEOMETRY` (or `SAME_AS`) is placed from its shape; any other type, a mod's say, gets a mid-sized fighter's shape. Seats measured from the cockpit camera only apply to your own jet.

## Smoke version (optional): every jet, single player or your own server

`Scripts\Hooks\SonicBoom.lua` puts DCS's white aircraft smoke on every airplane, AI or human, while it flies between Mach 0.97 and 1.05. It isn't in the mod's zip: copy it from this project's `Scripts\Hooks` into `Saved Games\DCS\Scripts\Hooks` if you want it.

- It only runs where the mission runs: single player, or a server you host. When you host, every player sees it.
- The smoke hangs in the air, so a long run near Mach 1 leaves a long white trail.
- It needs these lines at the end of `Saved Games\DCS\Config\autoexec.cfg`. They let every script in `Scripts\Hooks` run code inside missions, an API DCS labels "unsafe":

  ```lua
  -- SonicBoom: let Scripts/Hooks run code in the mission scripting state
  net = net or {}
  net.allow_unsafe_api = net.allow_unsafe_api or {}
  net.allow_unsafe_api[#net.allow_unsafe_api + 1] = "userhooks"
  net.allow_dostring_in = net.allow_dostring_in or {}
  net.allow_dostring_in[#net.allow_dostring_in + 1] = "mission"
  ```

## Frame capture (for development)

Press **Ctrl+Alt+Shift+K** in a mission. The DLL records how DCS draws the next frame to `capture-N.txt` next to it, in `Mods\tech\SonicBoom3D\bin`:

- every render target and depth buffer it draws into
- clears and viewports
- draw counts per pass
- the camera matrices it uploads

It costs nothing when you're not capturing. With **Advanced logging** on it also captures by itself, the first three times in a session that DCS shows frames without the vapor going into its picture (see the status line above): text only, no pictures, as `capture-1.txt` to `capture-3.txt`, each ending with whether the vapor went into DCS's picture that frame and when DCS last sent its main camera. Each new session writes over them. To capture what's needed by hand:

1. Tick Test mode on its Special page, then start a mission in a jet with mirrors (F-16C, F/A-18C or F-15E).
2. In an outside view (F2) with the cone visible, press Ctrl+Alt+Shift+K once.
3. In the cockpit (F1), look so a mirror is in view and press it again.
4. Send `capture-1.txt`, `capture-2.txt` and the `SONICBOOM` lines from `dcs.log`.

## For developers

- `src\SonicBoom3D.cpp` is the DLL, with `src\update.cpp`, its update check: GitHub's latest release fetched with WinHTTP on a thread of its own (the DLL kept loaded while it runs), its zip unpacked with Windows' `tar` into `%TEMP%` and only the mod's files copied over, the loaded DLL moved aside to `SonicBoom3D.dll.old` (removed at the next start); the popup and its buttons are `Mods\tech\SonicBoom3D\update.lua`, its sound `Sounds\update.wav` (`tools\make_update_sound.py`: a two-note chime, E5 then B5).
  - **Hooks:** it hooks `IDXGISwapChain::Present` and DCS's render-target changes. It saves and restores every piece of pipeline state it touches. Direct3D rewrites parts of the context's method table during the frame, so the hooks are put back on every target change.
  - **Cameras:** it reads DCS's cameras from the constant buffers DCS uploads. Each camera block holds the view, inverse view, projection and view-projection matrices. The one with the screen's aspect is the main view; one next to your head with a different aspect, or one looking back along the jet with its own near clip (the F-14's), is the mirror.
  - **Depth:** each ray stops at the 32-bit depth buffer that DCS renders each view with, so the jet and cockpit hide the cloud behind them.
  - **Drawing:** one quad covers the vapor's screen box. Each pixel ray-marches it: a cone whose vapor lies mostly on its two faces, a disc ahead of the flat shock and a shell inside its straight front,, broken up by a tileable 64³ two-channel noise texture made at start-up (Worley billows, and a silky domain-warped value noise), with fibres sampled around the axis and boiling through the third dimension over time, and big clumps streaming aft. One more sample per ray, where it enters the sheet, reads the same noise in world coordinates, in 600 m tiles, for the damp and dry air. Each sample's light is single scattering, less the sunlight the jet keeps off it (a rough jet: its wing flat from the root edges to the tip, its fuselage a tube; the way toward the sun crossing the wing or passing through the tube, soft at the edges, the softer the further from the jet): sunlight through a six-step march toward the sun (the sheet and its clumps), each pixel stepping it at a different depth and each step seeing the sheet's thin faces and rim spread over its length (so the shade doesn't turn to grain), a two-lobe Henyey-Greenstein phase, a powder term, and a share for light scattered more than once; plus sky light. Rays jump through the empty space either side of the sheet and step finely through it, each pixel's steps starting at its own offset from a 64×64 blue-noise texture made at start-up (void and cluster), moved on by the golden ratio every frame, the sim paused or not. So the steps' error shows as fine, even grain rather than a hatch, and in motion the eye averages it away: the vapor is drawn after DCS's TAA and DLSS, so nothing else does. Then reprojection: each view keeps what it showed (two half-float pictures of its size) and where each jet's cone sat in it, the hook sending a stable id per jet. The vapor, every jet's, goes first into two buffers as big as the biggest view: its colour, and how far it has moved on screen since last frame (its middle depth along the ray, a point in the cone, put back where that jet's cone was in this view last frame). It's then blended with what the pixel showed there, a tenth of the new each frame (about ten frames), kept within the range of the vapor around the pixel now so nothing lingers when it changes, and drawn onto the picture. Where there's no vapor now nothing older is shown, so nothing trails; a jump in the clock (a pause, a replay skipping) starts afresh. It's lit by the sun the hook sends, through the vapor toward the sun, plus skylight. Before it, a second quad multiplies the picture by the vapor's shadow: each pixel rebuilds its surface from DCS's depth and looks toward the sun through the vapor.
  - **Where it's drawn:** into each view's finished 8-bit picture (the screen, or each VR eye and inset), and into DCS's mirror image once per frame, once DCS has finished it (its sea and sky drawn in) and reads it. With DCS's MSAA the pictures and depth are multisampled, and the shaders read each pixel's first depth sample. If no view picture is found for a couple of seconds, it falls back to the screen at Present; the odd frames DCS presents without drawing the view (a hitch while it loads a model) get no vapor rather than vapor placed by another camera.
  - **DCS's HDR picture and light:** each view's HDR picture is kept as it finishes a pass with depth. When DCS tone-maps it (binds an 8-bit picture of the same size without depth, and reads the HDR picture in the pixel shader), the vapor goes into the HDR picture first, and the view's 8-bit picture then gets none. The light comes from DCS's per-frame constant buffer (`cPerFrame`, 608 bytes, laid out in `Bazar\shaders\common\context.hlsl`) and its ambient cube (`cAmbientMap`, 144 bytes, `common\AmbientCube.hlsl`), found among the uploads by size and contents, and is used as DCS's smoke uses it (`ParticleSystem2\common\psShading.hlsl`).
- `Mods\tech\SonicBoom3D` is the mod as installed: `entry.lua` declares it to DCS (its icon, `Theme`, and its settings page, `Options`: `optionsDb.lua` the settings and their defaults, `optionsData.lua` the words, `options.dlg` the layout, each setting's widget named after it plus `Checkbox`, `ComboList` or `Slider`, as DCS binds them). `jets.lua` holds each jet's shape and the cone's settings per aircraft, shared by the hook and the page; the page's "Cone per aircraft" widgets (`jet...`, which DCS binds to nothing) are wired up by `Options\jetsPage.lua` each time the page opens (`callbackOnShowDialog`), and everything they set is one plugin setting, `jets`. `tools\make_theme.py` makes the icons and the wallpapers from screenshots of it in DCS (`tools\theme_*.webp`) and `tools\make_dlg.py` writes `options.dlg`. The hook reads the page through DCS's `Options.Data` (`getPlugin("SonicBoom3D", name)`), every frame.
- `tools\package.py` builds `dist\SonicBoom3D-<version>.zip` (the version is `entry.lua`'s), the drop-in mod. `tools\publish.py` copies the same files into the mod's own repository (`..\SonicBoom3D`, its page and changelog), replacing its `Mods` and `Scripts`.
- `tools\camera_tour.lua` (not shipped) takes the camera round one jet of each airframe in "SonicBoom Mach 1 lineup", front, back, left, right, top and bottom, and has the DLL save each view (`SB.shot(path)`) to `Screenshots\SonicBoom tour\`; `tools\tour_sheets.py` makes a sheet per airframe and overviews of every airframe from them.
- `build.bat` builds the DLL with Visual Studio 2022, copies it into `Mods\tech\SonicBoom3D\bin`, and runs `src\harness.cpp`. The harness checks, without DCS:
  - the outside view, using the Lua camera
  - nothing ahead of the vapor's front; from above, the vapor reaching past the wingtips and back to the nozzles; head-on, a clear middle inside a brighter ring; its grain faint and even, with no hatch, once blended over a few frames; the softer cone filling the crisp one's outline with only a short glow past it, its grain fainter still, and halfway along the hard-to-soft slider a blend between them; a cone set to reach further up and less far down doing so, and one set 3 m forward drawn there; at 5.5 G its bottom drawn in, its top a little, and at -3 G the other way round; the jet's wing and fuselage shading the vapor under them, the vapor over them as it was; its reflection right under it on screen, about its own height, fainter twice as high and gone by 22 m, none over 80 ft; moving across the view, no trail; its shadow on the ground
  - DCS's own camera with depth, zoomed far in too (a 2 degree view frames the vapor as a 60 degree one 30 times nearer)
  - the mirror pass, and the F-14's square mirror with MSAA (but not a VR eye turned back)
  - VR eyes and quad-view insets, including Lua lagging a frame behind
  - other jets' vapor, with and without yours
  - DCS's light: its sun brighter, and the same into a multisampled (MSAA) picture, under its cloud shadow the sky's light alone, the jet's own lights in their colour, the sky's light from its ambient cube or environment cube, the cone placed by DCS's camera and clock, and a cone moved on a step too far for a frame counted and logged
  - GPU time at 4K, and that lower quality costs less and higher more
  - the frame capture
  - the update check without the network: versions compared, a release's page and zip found in GitHub's answer, installed into a Saved Games folder whose DLL is held open, only the mod's own files copied, the old DLL removed at the next start

  It also writes images to look at: `build\harness_side.bmp`, `harness_rear.bmp`, `harness_close.bmp` and `harness_dusk.bmp`, a cone set taller above and flatter below, `harness_shaped.bmp` and `harness_shaped_rear.bmp`, and one pulling 5.5 G and one pushing -3 G, `harness_pulling.bmp` and `harness_pushing.bmp`.
- `test_sonicboom.py` tests both Lua hooks against a mocked DCS (`pip install lupa`), the Special page's settings reaching the DLL included, the page's "Cone per aircraft" with DCS's widgets mocked from `options.dlg`, and the update popup with DCS's GUI mocked: shown in the main menu and never over a mission, and what each of its buttons does.
