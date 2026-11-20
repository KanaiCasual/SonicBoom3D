# Changelog

## 1.3 (in development)

Not released yet. This list grows until it is.

### New

- **Update check.** As DCS starts, SonicBoom3D asks GitHub whether there's a newer version. If there is, a window in the main menu says so (`1.3 → 1.4`) with a short chime, never over a mission:
  - **Update now** downloads it and installs it for you. Restart DCS to use it.
  - **Release page** opens its page in your browser, to install it yourself.
  - **Skip** doesn't ask about that version again.
  - **Remind later** (or Esc) asks again next time DCS starts.

  Nothing about you is sent. `UPDATE_CHECK = false` at the top of `Scripts\Hooks\SonicBoom3D.lua` turns it off.
- **The version you have** shows at the top right of Options > Special > SonicBoom3D.
- **Instability slider** (Options > Special > SonicBoom3D). In real footage near Mach 1 the vapor cone isn't always steady: parts of it vanish and come back, and now and then the whole cone disappears for a moment. Turn Instability up to get that. Missing parts are a quarter to half of the cone and come back within half a second or so; at 100% the whole cone is gone about a sixth of the time. Every jet gets its own timing. It's 0% to start with, so the cone looks as before until you turn it up.

## 1.2

### New

- **Cone per aircraft** (Options > Special > SonicBoom3D). Each aircraft type has its own cone settings, used for every jet of that type, yours and AI:
  - **Move cone forward** and **Front forward** (±25 ft each), **Width**, **Height above**, **Height below**, **Thickness**, and **Flashing and breathing**.
  - **Presets.** Each aircraft has a built-in **Default** that never changes. Moving a slider starts your own **Custom** preset. You can save presets under your own names, delete them, or **Reset** to Default.
  - **Vapor cone on this aircraft.** Untick it to turn the cone off for that type only, yours and AI. Its presets are kept.
  - The page opens on the aircraft you're sitting in.
- **G shapes the cone.** Pulling G gathers the vapor over the wing, as photos of jets pulling through Mach 1 show. From 1.5 G the bottom of the cone shrinks, and by 5.5 G it's nearly gone; the top shrinks a little. Pushing negative G does the opposite: from -0.5 G the top shrinks, and by -3 G it's nearly gone.
- **Pushing negative G brings the vapor in earlier**, as pulling G already did.
- **Hard to soft cone slider** (0 to 100%) replaces the Softer transonic cone tickbox. It covers everything from the crisp cone to the smooth mist.
- **Advanced logging** option, for bug reports. It writes more to `dcs.log` and records the first few frames the cone misses.

### Changed

- **The softer cone stays cone-shaped.** Its mist no longer trails far behind the jet or out ahead of the cone, so it keeps its point, slanted front and flat back.
- **The Thickness, Width and Flashing sliders moved into Cone per aircraft.** Values you set for them in 1.1 don't carry over.
- **Your jet's G is smoothed over about a second**, as other jets' already was, so buffet doesn't make the cone shimmer.
- **The settings at the top of `Scripts\Hooks\SonicBoom3D.lua` are in feet and nautical miles** instead of metres: `ALT_FULL_FT`, `ALT_FADE_FT`, `COCKPIT_RADIUS_FT`, `MAX_DISTANCE_NM`, `OTHER_DISTANCE_NM`. If you changed the old ones, set them again.

### Fixed

- **Zoomed far in** (a view a few degrees across), the cone was drawn tiny on the jet.
- **A farther jet's cone could show on top of a nearer one.**
- **The cone could jump for a frame when DCS stuttered while loading a model mid-flight.** Those frames now get no vapor instead of a misplaced cone.
- **Vapor no longer gets drawn onto the F10 map.**
- **The Special page's help text wraps** instead of being cut off.

## 1.1

### New

- **F-14A and F-14B now get the cone.** They don't draw their own vapor in DCS. Only the JF-17 and Mirage 2000C do, and the mod still leaves those alone when a player flies them.
- **Softer transonic cone** (Options > Special > SonicBoom3D): a smooth, cloud-like mist with soft, wispy edges like the JF-17's own vapor, instead of the crisp faces.
- **Full MSAA support.** With DCS's MSAA on, the vapor now goes into DCS's own picture before tone mapping and is lit by DCS's light, the same as with DLAA and DLSS. In 1.0 it fell back to being drawn on the finished picture.
- **Mirrors work with MSAA too**, and the F-14's mirror now shows the vapor.

### Fixed

- The cone could flicker, or jump behind the jet, with MSAA on.
- The cone could jump forward along the jet for a frame now and then, and had a small constant jitter. It now stays locked to the airframe, because its placement is timed to DCS's own simulation steps.
- Vapor in the mirrors could blink out for a frame at high speed.
- The vapor's streaming and boiling no longer stutter when DCS's simulation and your frame rate fall out of step.
- Softer cone: much less grain.

## 1.0

First release. A rebuild of Bush_Wookiee_92's original SonicBoom mod, made to work on most of DCS's airframes.

- **A volumetric vapor cone** shaped after real transonic photos: a crisp flat shock at the back, a straight-sided cone ahead of it, and a rim reaching past the wingtips. Head-on it's a halo.
- **It looks like condensation:** smooth, with clumps streaming aft and a rim that wavers and frays. It thickens and thins as the jet flies through damper and drier air.
- **Lit the way DCS lights its own smoke:** the sun, the sky, the afterburner's glow, the moon at night, and grey under an overcast. Looking toward the sun, it glows.
- **The jet shades its own vapor.** The vapor casts a soft shadow on the ground and the jet, and reflects in the sea, lakes and rivers.
- **It flashes in as you approach Mach 1**, is solid just below it, breathes gently, and breaks up past it. Pulling G brings it in earlier.
- **On your jet and the nearest other jets**, AI or human, in outside views, from the cockpit, and in the mirrors.
- **Single player and multiplayer** (client-side).
- **VR:** drawn into each eye, including eye-tracked Quad-Views-Foveated insets.
- **Anti-aliasing:** works with DLAA, DLSS or none. With MSAA it's drawn on the finished picture (fixed in 1.1).
- **IC-safe:** nothing in the DCS install is changed.
- **Settings** under Options > Special > SonicBoom3D: Vapor cone on/off, Quality (Low to Ultra), Thickness, Width, Flashing and breathing, the jet's shade, shadow, reflection, cockpit and mirrors, how many other jets, and a Test mode that shows the cone at any speed.
