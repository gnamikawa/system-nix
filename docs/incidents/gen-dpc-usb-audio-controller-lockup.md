# GEN-DPC USB audio controller lockup

## Symptom

The Behringer UMC202HD stops playing audio after working earlier in the same
boot. Firefox then stalls YouTube playback while it waits for its audio stream
to initialize. Unplugging the interface, disconnecting the StreamCam, and
trying another port may not recover it.

This failure was first diagnosed on 2026-08-14 and recurred on 2026-08-21 with
the identical PipeWire signature. See "Recurrences" below.

## Recurrences

| Date | UMC202HD port | Registration state | Recovery path used |
| --- | --- | --- | --- |
| 2026-08-14 diagnosis, 2026-08-15 recovery | `usb 1-3.2` (chipset, behind failed Cintiq hub) | double: stale `card0` at `1-3.2` + live `card3` at `usb 3-4` after cable move | `snd-usb-audio` unbind of the stale `1-3.2:1.0` interface |
| 2026-08-21 ~05:17 JST | `usb 1-4.2` (chipset, different port; no cable move performed) | single: only one registration wedged on the chipset bus | chipset xHCI rebind of `0000:02:00.0` |

The 2026-08-21 recurrence did not require the Cintiq hub to have failed first;
the chipset xHCI wedged with the UMC202HD on a different port and no
StreamCam/hub anomalies in the same session. This widens the failure envelope:
the chipset controller can lock up in isolation, not only as a downstream
effect of a failing hub.

## Hardware topology

GEN-DPC has two independent xHCI controllers:

- `0000:02:00.0`, AMD 400 Series chipset USB controller (`1022:43d5`), owns
  USB buses 1 and 2.
- `0000:0a:00.3`, AMD Matisse CPU USB controller (`1022:149c`), owns USB
  buses 3 and 4.

At failure time, the Cintiq Pro 22 hub was attached to the chipset controller
as `usb 1-3` and `usb 2-3`. The UMC202HD was `usb 1-3.2`, the Cintiq tablet was
`usb 1-3.3`, and the StreamCam was `usb 2-3.1`.

The four blue rear USB 3.1 Gen 1 ports use the CPU controller. The red rear
USB-A port and rear USB-C port use the chipset controller.

## Evidence and diagnosis

The kernel recorded the following progression:

1. About twelve minutes after boot, `xhci_hcd 0000:02:00.0` reported eight
   isochronous buffer-overrun events for slot 4, endpoint 4. The enumeration
   order makes the UMC202HD the likely slot 4 device, but the log does not
   identify that mapping directly.
2. Roughly fourteen and a half hours later, the Cintiq SuperSpeed hub at
   `usb 2-3` stopped returning device descriptors. Reset and port power-cycle
   attempts ended with `error -110` and `unable to enumerate USB device`.
3. The UMC202HD then failed USB Audio Class clock-validity and sample-rate
   requests with `error -110`.
4. The Cintiq USB 2 hub began returning
   `hub_ext_port_status failed (err = -110)` every 5.76 seconds. Bluetooth on
   another root port of the same controller also timed out.
5. Moving the UMC202HD to another chipset-controller port produced descriptor
   timeouts. Moving it to a blue rear port enumerated it immediately as
   `usb 3-4` on `0000:0a:00.3`.

The successful enumeration on the independent controller proves that the
UMC202HD and its cable were functional. Multiple failed root ports localize
the active fault to the chipset xHCI domain, below ALSA, PipeWire, and
Firefox.

The failed Cintiq hub could not report the UMC202HD's removal. Linux therefore
retained the old device as ALSA `card0` while registering the live connection
as `card3`. PipeWire continued opening `usb 1-3.2`; each open waited through
USB clock-control timeouts. Firefox stalled while PipeWire attempted to
initialize that dead stream.

## Confirmed recovery

Two recovery paths have worked, for two different registration states. Check
the current state before choosing:

- If two UMC202HD registrations exist (stale card behind a failed hub plus a
  live card enumerated on the CPU controller after a cable move), use the
  `snd-usb-audio` unbind path below. This is what recovered the 2026-08-15
  incident.
- If only one registration exists and it is wedged in place (no cable move,
  the device is still on the chipset bus), rebind the chipset xHCI PCI
  device — see the second block below. This is what recovered the 2026-08-21
  incident.

### snd-usb-audio unbind (double-registration case)

First identify both paths. Do not assume ALSA card numbers remain stable:

```console
$ rg -l '^1397$|^0507$' \
    /sys/bus/usb/devices/*/idVendor \
    /sys/bus/usb/devices/*/idProduct
```

After confirming that `usb 3-4` is the live UMC202HD and `usb 1-3.2` is the
stale instance, detach only the stale sound interface:

```console
$ echo '1-3.2:1.0' | sudo tee \
    /sys/bus/usb/drivers/snd-usb-audio/unbind
```

This command recovered YouTube playback during the incident. It supplies the
logical disconnect that the failed hub could not report. It does not change
persistent configuration, and normal enumeration binds the driver again on a
future boot.

### Chipset xHCI rebind (single-registration case, or full-controller recovery)

If the whole chipset USB controller must be recovered, unbind and bind its
xHCI driver:

```console
$ echo '0000:02:00.0' | sudo tee \
    /sys/bus/pci/drivers/xhci_hcd/unbind
$ echo '0000:02:00.0' | sudo tee \
    /sys/bus/pci/drivers/xhci_hcd/bind
```

This temporarily disconnects the Cintiq USB functions, StreamCam, Bluetooth,
and every other device on buses 1 and 2. The UMC202HD on buses 3 or 4 is not
affected.

The 2026-08-21 recurrence recovered with exactly this command sequence. The
UMC202HD was on the chipset bus (`usb 1-4.2`) at the time, and came back
cleanly on the same port after the rebind.

Do not write to `/sys/bus/pci/devices/0000:02:00.0/reset`. Its advertised
reset method is `bus`, so it may reset sibling chipset functions, including
SATA.

## Prevention status

Disabling USB autosuspend does not address this failure. The controller
stopped answering across several root ports while devices remained logically
present.

The motherboard is a Gigabyte B450 AORUS PRO WIFI running BIOS F51 from
2020-07-29. AMD later shipped AGESA 1.2.0.2 for intermittent USB dropouts and
USB audio failures. Gigabyte offers stable BIOS F66 with AGESA 1.2.0.F for
this board.

Updating to stable BIOS F66 is the leading prevention action, but it has not
yet been tested on GEN-DPC. Until a later incident-free observation period
confirms it, treat the firmware explanation as a strong hypothesis rather
than a proven fix.

The 2026-08-21 recurrence occurred seven days after the initial diagnosis
with BIOS F51 still in place, no cable move between incidents, and the
UMC202HD on a different chipset port than the first occurrence. This
strengthens the chipset/AGESA hypothesis: the wedge is reproducing on the
same controller without needing the specific 2026-08-14 topology to
reappear. The BIOS update remains the outstanding prevention action.

## References

- [AMD: Updated AGESA Coming for Intermittent USB Connectivity](https://community.amd.com/t5/adrenalin-release-notes/updated-agesa-coming-for-intermittent-usb-connectivity/ta-p/456762)
- [Gigabyte B450 AORUS PRO WIFI BIOS downloads](https://www.gigabyte.com/Motherboard/B450-AORUS-PRO-WIFI-rev-1x/support)
- [Linux sysfs ABI documentation](https://docs.kernel.org/admin-guide/abi.html)
