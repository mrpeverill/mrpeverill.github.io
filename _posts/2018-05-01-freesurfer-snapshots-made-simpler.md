---
layout: post
title: Freesurfer snapshots made simpler
date: 2018-05-01 17:38:00
---
<h1>Introduction</h1>
There a lot of reasons why you would want to programatically collect screenshots from Freesurfer tools. For one, it's a lot simpler to generate QA reports of your parcellations than to go through and manually inspect each brain volume one more time.

Second, Freesurfer is a great tool for generating figures. You can use tksurfer to project statistical maps from FSL or other programs on a 3d image of the brain surface. Add in some imagemagick scripting and you can very easily create some nifty figures:

<a href="{{ site.url}}/assets/img/2018/04/examplequadfig.png"><img class="alignnone size-full wp-image-21" src="{{ site.url}}/assets/img/2018/04/examplequadfig.png" alt="" width="240" height="206" /></a>

(image from: Peverill, M., McLaughlin, K. A., Finn, A. S., &amp; Sheridan, M. A. (2016). Working memory filtering continues to develop into late adolescence. <i>Developmental Cognitive Neuroscience</i>. https://doi.org/10.1016/j.dcn.2016.02.004)

That being said, complications are always the rule in computer land. Freesurfer is written using <a href="https://en.wikipedia.org/wiki/Tcl">Tcl/Tk</a>, which is a powerful but quircky programming language used to create gui applications. Partly because of this limitation, the way snapshots are taken is that a command is run in the tcl script 'SaveTiff' which saves a TIFF image of whatever is displayed in the users window. If your window is front and center, great. BUT if your screensaver comes on, if part of the window is obscured, or if your screen isn't big enough, your snapshot will be corrupted. This also means that the process can't be parallelized (for example, you need to generate QA reports one at a time) because otherwise the windows will interfere with one another. This also means you can't wrap up QA generation in your normal workflow.

Note: These days tkmedit and tksurfer are somewhat deprecated in favor of freeview, a more sophisticated program that has its own snapshotting interface. I'm using the former tools because the QA-tools script uses them, but xvfb should also work with freeview.
<h1>What is Xvfb</h1>
That said, this is Linux, which means that someone has likely already solved this problem. Graphics in unix usually run through x windows. When you run say, firefox, from the command line the application looks in your environment to see what the default 'x server' is set to. Then it will display the window on that server (your screen). This is why firefox fails if you run it in a normal ssh window. If you ran ssh from a mac with the -X option, it will know to try to open the window on your local x server, and the app opens on your desktop.

<a href="https://www.x.org/archive/X11R7.6/doc/man/man1/Xvfb.1.xhtml">Xvfb</a> is a virtual x server intended for testing graphical applications. So if we need to take some Freesurfer snapshots, instead of dealing with the idiosyncrocies of our local display, we can just just start an isolated dedicated x server for that subject's Freesurfer, open the window there (it won't actually show up anywhere), take our screenshot, and close it when we are done.
<h1>Minimal Example</h1>
Here's a minimal example. We're going to use xvfb-run to open up tksurfer and take a screenshot. In production, you would want to test out the tcl commands first in your normal environment to make sure you were taking the picture you want, but this will just show you how it works. You will need Xvfb installed on your server, and you will need to have freesurfer set up.
{% highlight plaintext %}{% raw %}
mrpev@vmpfc$xvfb-run --server-args "-screen 0 1920x1080x24" tksurfer fsaverage lh pial -gray -mni152reg #everything after this is in tcl
subject is fsaverage
hemi is lh
surface is pial
surfer: current subjects dir: /mnt/stressdevlab/fear_pipeline/edited_FreeSurfer
surfer: not in "scripts" dir ==&gt; using cwd for session root
surfer: session root data dir ($session) set to:
surfer: /mnt/stressdevlab/fear_pipeline/edited_FreeSurfer
checking for nofix files in 'pial'
Reading image info (/mnt/stressdevlab/fear_pipeline/edited_FreeSurfer/fsaverage)
Reading /mnt/stressdevlab/fear_pipeline/edited_FreeSurfer/fsaverage/mri/orig.mgz
surfer: Reading header info from /mnt/stressdevlab/fear_pipeline/edited_FreeSurfer/fsaverage/mri/orig.mgz
surfer: vertices=163842, faces=327680
surfer: curvature read: min=-0.673989 max=0.540227
surfer: single buffered window
surfer: tkoInitWindow(fsaverage)
surfer: using interface /usr/local/freesurfer/stable5_3/tktools/tksurfer.tcl
Reading /usr/local/freesurfer/stable5_3/tktools/tkm_common.tcl
Reading /usr/local/freesurfer/stable5_3/tktools/tkm_wrappers.tcl
Reading /usr/local/freesurfer/stable5_3/lib/tcl/fsgdfPlot.tcl
Reading /usr/local/freesurfer/stable5_3/tktools/tkUtils.tcl
Successfully parsed tksurfer.tcl
reading white matter vertex locations...
% make_lateral_view #these are entered manually.
% redraw
% save_tiff example.tiff
% exit
mrpev@vmpfc:/mnt/stressdevlab/fear_pipeline/edited_FreeSurfer$eog example.tiff #this just opens the image for viewing.
{% endraw %}{% endhighlight %}

If everything goes well, you shouldn't see any windows running but you should still get a screenshot at the end.  If you don't want to enter the tcl commands manually (and why would you?) you can put them in a tcl script and specify the script when you run tksurfer using the -tcl option.

<a href="{{ site.url}}/assets/img/2018/04/capture.png"><img class="alignnone size-medium wp-image-23" src="{{ site.url}}/assets/img/2018/04/capture.png?w=300" alt="" width="300" height="274" /></a>
<h1>Parallel generation of QA reports using Freesurfer qa-tools and Xvfb</h1>
Freesurfer publishes a powerful library, QAtools, to generate QA reports. But this involves, you guessed it, lots of snapshots. So it takes forever if you have a big dataset. We can use xvfb to address this. This is the code that needs to be run for each subject:
<pre>[sourcecode language="bash"]
export SUBJECTS_DIR=(FREESURFER SUBJECT DIRECTORY)
export QA_TOOLS=(PATH TO QAtools)
xvfb-run -a --server-args "-screen 0 1920x1080x24" -e /dev/stderr $QA_TOOLS/recon_checker -s (SUBJECTID) -snaps-only -snaps-detailed -snaps-overwrite -snaps-out $SUBJECTS_DIR/QA/QA_check(SUBJECTID).html</pre>
A few notes on this:
<ul>
	<li>The -a option to xvfb-run makes sure that each process doesn't try and run on the same x display.</li>
	<li>recon_checker will fail if you don't specify a separate html file per subject (because parallel processes will try to write to the same file).</li>
</ul>
Then you run the script using qsub:
{% highlight bash %}{% raw %}
qsub -cwd -V -S /bin/bash runqa.sh</pre>
{% endraw %}{% endhighlight %}
(there are a variety of ways to execute this smoothly across many subjects, including gnu make, a simple script executing a for loop with string substitution, etc. That's a subject for another post)

When you are done, you should have finished QA reports for each subject. The only downside is that, because the index page is generated by the qa_tools program, you'll need to regenerate it. You can do this with a for loop like so:

{% highlight bash %}{% raw %}
for i in QA_check1???_1.html; do sed '3q;d' $i; done &gt; qareport.html
{% endraw %}{% endhighlight %}