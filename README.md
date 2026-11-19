# SonicBoom3D: Transonic Vapor Cones for DCS World

![SonicBoom3D: an F/A-18C pulling 9 G through Mach 1, the vapor gathered over its wing](images/title-fa18c-pulling-9g.jpg)

Real 3D vapor cones for every supersonic-capable jet in DCS World: yours, the AI's and other players'.

Push into the transonic band and a condensation cone forms around the jet. It's shaped from real photos and drawn as a true volume, not flat sprites.

- Lit by DCS's own sun, sky, moon and afterburner glow, so it fits any time of day and weather
- Forms from Mach 0.94, solid from 0.97 to 1.01, gone by 1.03 (earlier when you pull or push G)
- Casts a shadow, reflects in water, shows from the cockpit and in the mirrors
- Flat screen and VR, with MSAA, DLAA or DLSS, IC-safe
- Multiplayer: client-side, nothing on the server

**Latest release: 1.2** ([Releases](../../releases), and [ED User Files](https://files.digitalcombatsimulator.com/en/files/3352000/)). What changed: see the [changelog](CHANGELOG.md).

Updates, bug reports and feedback: [Discord](https://discord.gg/hAy2gTF7R2)

## What you get

- **A volumetric cone shaped after real transonic photos:** a crisp flat shock at the back, a straight-sided cone ahead of it, and a rim reaching past the wingtips. Head-on it's a halo.
- **It looks like condensation:** smooth, with clumps streaming aft and a rim that wavers and frays. It thickens and thins as the jet flies through damper and drier air.
- **Lit the way DCS lights its own smoke:** the sun, the sky, the afterburner's glow, the moon at night, and grey under an overcast. Looking toward the sun, it glows.
- **The jet shades its own vapor.** The vapor casts a soft shadow on the ground and the jet, and reflects in the sea, lakes and rivers.
- **It flashes in as you approach Mach 1**, is solid just below it, breathes gently, and breaks up past it.
- **G shapes it.** Pulling G gathers the vapor over the wing and pushing gathers it under, and either one brings it in earlier, as in real life.
- **Your own look for each aircraft:** move it, stretch it, make it wider, taller or flatter, thicker or steadier, and save presets. You can also turn it off for any aircraft.
- **From crisp to soft:** a slider goes from the crisp cone to a smooth mist with soft edges, like the JF-17's own vapor.
- **On your jet and the nearest other jets** (AI or human), in outside views, from the cockpit, and in the mirrors (the F-14's included).
- **VR:** drawn into each eye, including eye-tracked Quad-Views-Foveated insets. Tested with SteamVR OpenXR.
- **Any anti-aliasing:** MSAA, DLAA, DLSS or none, always lit by DCS's own light.
- **IC-safe:** nothing in the DCS install is changed.

## Pictures

In-game, unedited, scaled to 1920×1080 (the options page cropped to its window).

| | |
|---|---|
| ![F-16C pulling 8 G](images/1.2/f16c-pulling-8g.jpg) | ![F-16C pulling 8 G, from behind](images/1.2/f16c-pulling-8g-from-behind.jpg) |
| F-16C pulling 8 G (AI): the vapor over the wing | F-16C pulling 8 G, from behind |
| ![F-16C, its cone reshaped](images/1.2/f16c-cone-reshaped.jpg) | ![The Special options page](images/1.2/options-special-page.jpg) |
| F-16C, its cone reshaped: taller, flatter below, longer | Options > Special > SonicBoom3D |
| ![F-15E, the softer cone](images/1.2/f15e-softer-cone.jpg) | ![F-15E, half soft](images/1.2/f15e-half-soft.jpg) |
| F-15E, the softer cone | F-15E, halfway from crisp to soft |
| ![F-14B mirror](images/1.1/f14b-mirror.jpg) | ![F-14B side on](images/1.1/f14b-side-on.jpg) |
| F-14B, in the mirror | F-14B, side on |
| ![F-15E, 1.1's softer cone](images/1.1/f15e-softer-cone.jpg) | ![F-15E into the sun](images/1.1/f15e-into-the-sun.jpg) |
| F-15E, the softer cone as it was in 1.1 (now cone-shaped) | F-15E, into the sun |
| ![F-16C side on](images/1.1/f16c-side-on.jpg) | ![F/A-18C carrier sunset](images/1.1/fa18c-carrier-sunset.jpg) |
| F-16C, side on | F/A-18C, carrier at sunset |
| ![F/A-18C past the carrier](images/1.0/fa18c-past-the-carrier.jpg) | ![F/A-18C formation](images/1.0/fa18c-formation.jpg) |
| F/A-18C, past the carrier | F/A-18C formation |
| ![Su-27 into the sun](images/1.0/su27-into-the-sun.jpg) | ![B-1B from below](images/1.0/b1b-from-below.jpg) |
| Su-27, into the sun | B-1B, from below (AI) |
| ![AJS 37 over the forest](images/1.0/ajs37-over-the-forest.jpg) | ![F-15E into the sun](images/1.0/f15e-into-the-sun.jpg) |
| AJS 37 Viggen, over the forest | F-15E, into the sun (1.0) |

## Install

1. Download the zip from [Releases](../../releases).
2. Extract it into `C:\Users\<you>\Saved Games\DCS\`, or add it to OvGME as it is. You get:
   - `Mods\tech\SonicBoom3D\`: the mod, its icon, its settings page, and the DLL that draws the cone
   - `Scripts\Hooks\SonicBoom3D.lua`: the hook that feeds your jet and camera to the DLL
3. Restart DCS.

The SonicBoom3D icon shows on the main menu's bar, and its settings are under **Options > Special > SonicBoom3D**.

**Updating:** extract the new zip over the old one (or replace it in OvGME) and restart DCS. Your settings are kept, apart from what the [changelog](CHANGELOG.md) says.

This repository holds the mod as it stands: its `Mods` and `Scripts` folders drop straight into `Saved Games\DCS`. Between releases they're the version in development.

## Multiplayer

It's client-side: nothing goes on the server, and only players with the mod see the cones. What you see depends on the server's export settings:

- **On your own jet:** the server must allow own-aircraft export (`allow_ownship_export` in `serverSettings.lua`). Most servers do.
- **On other jets:** the server must also allow object export (`allow_object_export`). Without it you still get the cone on your own jet.

Other players don't need the mod for you to see it on their jets.

## Settings

**Options > Special > SonicBoom3D**. Changes apply straight away, in flight too.

- **Vapor cone:** on or off.
- **Quality:** Low to Ultra.
- **Hard to soft cone:** from the crisp cone (0%) to a smooth mist (100%), or anywhere between.
- **Cone per aircraft:** pick an aircraft (the page opens on the one you're in).
  - **Vapor cone on this aircraft:** untick to turn it off for that type, yours and AI.
  - **Move cone forward** and **Front forward** (±25 ft), **Width**, **Height above**, **Height below**, **Thickness**, and **Flashing and breathing**.
  - **Presets:** each aircraft's **Default** never changes. Moving a slider starts your own **Custom** preset. **Save as new preset** keeps it under a name, **Delete** removes one, and **Reset** goes back to Default.
  - Settings apply to every jet of that type, yours and AI.
- **Light and shade:** the jet shades its vapor from the sun, its shadow on the ground, the sea and the jet, and its reflection in water.
- **Where it shows:** from the cockpit, in the cockpit mirrors, and on other jets (none, or the nearest 5, 10, 25 or 50).
- **Test mode:** shows the cone at any speed and height, to check how it lines up.
- **Advanced logging:** writes more to `dcs.log` for bug reports.

More settings (Mach range, altitude fade, distances) are at the top of `Scripts\Hooks\SonicBoom3D.lua`, described in the mod's own read-me, `Mods\tech\SonicBoom3D\README.md`.

## Good to know

- **GPU cost** at High: about 1.9 ms at 4K with the cone filling the screen (Low 1.35 ms, Ultra 2.55 ms). Other jets cost only what their vapor covers on screen.
- **The JF-17 and Mirage 2000C draw their own vapor** in DCS, so when a player flies one, this mod leaves it alone. AI ones get this cone.
- **Other jets' vapor is worked out from their flight path**, since DCS doesn't give mods their speed or G. Expect it to start and stop a little later than on your own jet.

## Uninstall

Delete `Saved Games\DCS\Mods\tech\SonicBoom3D` and `Saved Games\DCS\Scripts\Hooks\SonicBoom3D.lua`.

## Credits

Original mod by Bush_Wookiee_92. Many thanks to him for letting me rebuild it and make it work on most of DCS's airframes.
