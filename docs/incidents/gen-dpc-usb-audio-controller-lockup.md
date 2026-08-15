# GEN-DPC USB audio controller lockup

## Symptom

The Behringer UMC202HD stops playing audio after working earlier in the same
boot. Firefox then stalls YouTube playback while it waits for its audio stream
to initialize. Unplugging the interface, disconnecting the StreamCam, and
trying another port may not recover it.

This incident was diagnosed on 2026-08-14 and recovered on 2026-08-15 without
rebooting.

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

## References

- [AMD: Updated AGESA Coming for Intermittent USB Connectivity](https://community.amd.com/t5/adrenalin-release-notes/updated-agesa-coming-for-intermittent-usb-connectivity/ta-p/456762)
- [Gigabyte B450 AORUS PRO WIFI BIOS downloads](https://www.gigabyte.com/Motherboard/B450-AORUS-PRO-WIFI-rev-1x/support)
- [Linux sysfs ABI documentation](https://docs.kernel.org/admin-guide/abi.html)
