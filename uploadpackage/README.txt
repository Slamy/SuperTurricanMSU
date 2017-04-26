
-------------------- Super Turrican MSU Hack v0.4 -----------------------

This hack does not include the ROM file. You need to get a ROM of
the European or the US version and patch it.

Expected MD5SUM of original ROMs to be sure you got the right thing.

Europe  PAL    90c9fe8386a7f69de475c58bb8de01f7  Super Turrican (Europe).sfc
USA     NTSC   24d31806dd79e6e2be36ef27b51c8858  Super Turrican (USA).sfc

Expected MD5SUMs of patched ROMs to be sure the patcher worked correctly:

Europe  PAL    97c335ee26ae368b734a304c0e9d0b89  supertur_msu1.sfc
USA     NTSC   bb86afd45871a361a94b6982c22c5b02  supertur_msu1.sfc


Patch the ROM file using Flips or similar software to get the expected ROM file.
Use the result with Higan or SD2SNES Rev. G and higher.


-- For SD2SNES Rev F. and older --

Old versions of the sd2snes have a reduced MSU volume compared to higan
and newer versions of the board.
Use the versions from subfolder sd2snesRevF and proceed as usual.

Europe  PAL    6251bdac096f7fb163d9eba5fe88f91d  supertur_msu1.sfc
USA     NTSC   ea14c8c74034bea6893a6644284e28af  supertur_msu1.sfc


--Credits--
Game Mod (by Slamy)
Music from Turrican Soundtrack Anthology (by Chris Hülsbeck, buy the Soundtrack at https://chrishuelsbeck.bandcamp.com/)


--Contact--

If you find any bugs or run into issues please contact me through my blog:
  http://slamyslab.blogspot.de/


--Known Bugs--
- During the title screen the cursor usually blinks. On a real SNES it doesn't do that until you move it. (only affects NTSC version)
- If you enable "Ingame Hooks" on your sd2snes the title screen is lacks my version number.
  I really hope this is the only thing affected
- Soundglitch could still be around somewhere. A soundeffect doesn't stop playing. The game crashes on the next time the SPC is loaded with data.


  
--Disclaimer--
Please keep in mind that you get this software package as is. If it damages your hardware and/or gives you a heart attack while playing do not blame me.


--Changelog--
2017-03-29 v0.4
	Assumed to fix Soundglitch (Removed 16 bit writes to $2140, further tests needed)
	Fix swapped music of stages 1-2 and 1-3
	Replaced IPS by BPS and more cleaned up package
	Moved volume boosted sd2snes version for revision F and older into subfolder.
	Now assumes to be run on higan or sd2snes rev G or newer.

2016-10-02 v0.3
	Added US NTSC version

2016-09-30 v0.2
	First published version
	Fixed Level 2-3 Boss Music
	Synced Opening Music with Video
	Changed title text
	Fixed text corruption in intro and outro
	
2015-07-22 v0.1
	Unpublished version but complete with all music and an Easter Egg



--Complete file list of files--

./README.txt
./NTSC
./NTSC/manifest.bml
./NTSC/supertur_msu1.bps
./PAL
./PAL/manifest.bml
./PAL/supertur_msu1.bps
./sd2snesRevF
./sd2snesRevF/NTSC
./sd2snesRevF/NTSC/supertur_msu1.bps
./sd2snesRevF/PAL
./sd2snesRevF/PAL/supertur_msu1.bps
./supertur_msu1-1.pcm
./supertur_msu1-2.pcm
./supertur_msu1-3.pcm
./supertur_msu1-4.pcm
./supertur_msu1-5.pcm
./supertur_msu1-6.pcm
./supertur_msu1-8.pcm
./supertur_msu1-9.pcm
./supertur_msu1-11.pcm
./supertur_msu1-13.pcm
./supertur_msu1-14.pcm
./supertur_msu1-15.pcm
./supertur_msu1-16.pcm
./supertur_msu1-19.pcm
./supertur_msu1-20.pcm
./supertur_msu1-21.pcm
./supertur_msu1-22.pcm
./supertur_msu1.msu


