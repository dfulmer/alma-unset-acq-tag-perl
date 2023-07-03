# alma-unset-acq-tag-perl

The goal of this project is to create an itemized set in Alma of all Physical Titles which only have an item or items with a Process Type = Acquisition. Then, using that set as the input, to run a job in Alma which will make the Management Tag = Don’t Publish.

In order to get a set of bib records which have only an item or items with the process type equal to "Acquisition" you must begin with a logical set of all Physical Titles where (Process type equals "Acquisition") (Set A), then create a second logical set of Physical Titles where Process type equals [every single Process type, including empty, but excluding "Acquisition"] (Set B), then combine the sets: Set A NOT Set B so that you end up with an itemized set (Set C). This is the set that you want to submit to the Set Management Tags job to set the export value as "Don’t Publish."

To give a concrete example: say the library has a monograph, Title A, with 10 copies and a Management Tag of "Publish Bib" then orders one more copy, an added copy or a replacement copy, for example. It is in Set A, because it is in the logical set of all Physical Titles where (Process type equals "Acquisition"), it is also in Set B because it has an item with a Process type of, let's say, empty, or Loan, or even both, so it is not in Set C (which is Set A NOT Set B). Set C is the set where the Management Tag will be changed to "Don't Publish" so Title A will keep its "Publish Bib" Management Tag.

## Configuration in Alma

There needs to be two logical sets in Alma, which will be combined with the NOT operator:

OCLC_every_physical_title_with_acquisition_v2
Physical Titles where (Process type equals "Acquisition")
![seta](https://github.com/dfulmer/alma-unset-acq-tag-perl/assets/18075253/31bc5616-1c82-4ed0-9991-31c67d026d25)

OCLC_every_physical_title_except_acquisition_v2
![setb](https://github.com/dfulmer/alma-unset-acq-tag-perl/assets/18075253/15c28bd7-c258-474c-8700-b86543d5e4ed)

## Creating the set and changing the Management Tags manually

Follow these steps to create the itemized set of Physical Titles which have exclusively items where Process Type = Acquisition and change the Management Tags of those Physical Titles in the Alma GUI.

* Unset the Publish tag when it shouldn’t be set
  * Relevant logical sets are
    * OCLC_every_physical_title_with_acquisition_v2
    * OCLC_every_physical_title_except_acquisition_v2
  * Create an itemized set by combining the two above sets:  OCLC_every_physical_title_with_acquisition_v2 NOT OCLC_every_physical_title_except_acquisition_v2
    * From the “Manage Sets” page, “OCLC_every_physical_title_with_acquisition_v2”, select combine sets
    * Change the Operation to “Not”
    * Select “OCLC_every_physical_title_except_acquisition_v2”
    * Change the set name to “OCLC_remove_publish_bib_acq combined”
    * Click on “Submit”
    * [Note: check back while Alma calculates the number of records involved, because you have to confirm that step]
    * This step can take up to 2 hours or longer
* Run “Set Management Tags” job, using the “OCLC_remove_publish_bib_acq combined” set, and set the tag to “Don’t publish”.

## Creating the set and changing the Management Tags via scripts

There are two programs which carry out the two steps described above.
```
alma-unset-acq-tag-create-set.pl
```
This program combines OCLC_every_physical_title_with_acquisition_v2 NOT OCLC_every_physical_title_except_acquisition_v2 into an itemized set, the name of which begins with “OCLC_every_physical_title_with_acquisition_v2 - Combined - “
```
alma-unset-acq-tag-set-management-tags.pl
```
This program runs the “Set Management Tags” job on the newly created itemized set and it sets the Management Tags of all members of that set to “Don’t publish” regardless of what it has for a Management Tag.

This is how to use the two scripts from your computer:

Clone the repo

```
git clone git@github.com:dfulmer/alma-unset-acq-tag-perl.git
cd alma-unset-acq-tag-perl
```

copy .env-example to .env

```
cp .env-example .env
```

edit .env with actual environment variables.
Also, edit ‘alma-unset-acq-tag-create-set.pl’ with the correct sets.
Also, potentially edit ‘alma-unset-acq-tag-set-management-tags.pl’, but only if you want to do it using the old method with the larger set.

Build container
```
docker build -t mydocker .
```

Run container with a shell
```
docker run -it --rm -v ${PWD}:/app mydocker
```

Give command:
```
perl alma-unset-acq-tag-create-set.pl
```

Wait a couple of hours.
Give command:
```
perl alma-unset-acq-tag-set-management-tags.pl
```

Then type ‘exit’ and enter.

## Scheduling the scripts

To automate the process,
put these three files in a directory of your choice:

```
.env
alma-unset-acq-tag-set-management-tags.pl
alma-unset-acq-tag-create-set.pl
```

Check the .env file to make sure you have the API key that you want (Sandbox/Production).
Check alma-unset-acq-tag-create-set.pl to make sure you have the right sets and have commented out the wrong sets.

Here is how to edit your crontab file so the scripts will run automatically. In your terminal type:
```
crontab -e
```
and press "Enter". Arrow down to where you want to change it. Press “i” - to get in insert mode.

Make your changes. For example, this would run the first script at 1am and the second at 5am every day:
```
00 01 * * * perl /path/to/scripts/alma-unset-acq-tag-create-set.pl
00 05 * * * perl /path/to/scripts/alma-unset-acq-tag-set-management-tags.pl
```

Press “Escape” to exit insert mode, then press “:” then press “x” then press “Enter”.
