/*isom_class_check.m

  Use this script to generate isomorphism class of curves data:

    ls ./data/sorted_data/ | parallel -j25 "magma -b InputFileName:={} isom_class_check.m &"
    
  (current) If parallel does not work, run this script within /data/ directory :
  
  find ./ -type f | grep txt | perl -ne 'chomp;s/\.\///;print "magma -b InputFileName:=$_ ../isom_class_check.m &\n"' > RUN
  emacs -nw RUN
  chmod u+x RUN
  ./RUN
  
  Comments on the current method:
  - find ./ -type f | grep txt | grep ^./with  | perl -ne 'chomp;s/\.\///;print "magma -b InputFileName:=$_ ../isom_class_check.m &\n"' > RUN
  - writes a bash script file to run magma file in parallel. need to select files with certain beginnings, #!/bin/sh on top on RUN
  - use several data folders to manage batches (BU server limit)
  - approx 30-35 .txt files in each data folder

  This will take the data files in `./data/sorted_data/`, and for each curve in each file,
  will generate a new file (appended with `isomclass_`) in the same directory.

*/

/*

 parallel:
 
 RealInputFileName := "./data/" cat InputFileName;
 OutputFileName := "-/data/with_genus_" cat InputFileName;

*/

OutputFileName := "isom_" cat InputFileName;
LinesOfInputFile := Split(Read(InputFileName), "\n");

L := #LinesOfInputFile;

A<x,y>:= AffineSpace(GF(2),2);

// Quick construction of function field with IsIsomorphic functionality
function FFConstruction(fsupp)
    return AlgorithmicFunctionField(FunctionField(Curve(A,fsupp)));
end function;

// Each line is a support ordered by point count, so we need to get starting and ending indices
function CountIndices(TxtFile, InitialPointCounts,StartingIndex)
    if StartingIndex eq L then
        return StartingIndex;
    end if;
    for k in [StartingIndex..L] do
        tmp := eval(TxtFile[k]);
        if tmp[1] eq InitialPointCounts and k le L-1 then
            continue;
        elif tmp[1] eq InitialPointCounts and k eq L then
            return k;
        else
            return k-1;
        end if;
    end for;
end function;



// Main loop: check for pairwise isomorphism by varying over elements of the same point counts
i := 1;
while i le L do
    lst := eval(LinesOfInputFile[i]);
    ct := lst[1];
    supp := lst[2];
    F0 := FFConstruction(supp);
    autsize := #AutomorphismGroup(Curve(A,supp));
    fprintf OutputFileName, "[" cat "%o" cat "," cat "%o" cat "]" cat "\n", supp[1],autsize;
    tmp := [F0];
    j := CountIndices(LinesOfInputFile,ct,i);
    for ind in [i..j] do
        lst2 := eval(LinesOfInputFile[ind]);
        supp2 := lst2[2];
        F02 := FFConstruction(supp2);
        if forall(u){m : m in tmp | IsIsomorphic(F02,m) eq false } eq true then
            Append(~tmp,F02);
            autsize := #AutomorphismGroup(Curve(A,supp2));
            fprintf OutputFileName, "[" cat "%o" cat "," cat "%o" cat "]" cat "\n", supp2[1],autsize;
        end if;
    end for;
    i := j + 1;
end while;


quit;
