# 
# File: NuGet.New-PrigStubsCs.ps1
# 
# Author: Akira Sugiura (urasandesu@gmail.com)
# 
# 
# Copyright (c) 2012 Akira Sugiura
#  
#  This software is MIT License.
#  
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#



function New-PrigStubsCs {
    param ($WorkDirectory, $AssemblyInfo, $Section, $TargetFrameworkVersion)

    $results = New-Object System.Collections.ArrayList
    
    foreach ($namespaceGrouped in $Section.GroupedStubs) {
        $dir = $namespaceGrouped.Key -replace '\.', '\'

        foreach ($declTypeGrouped in $namespaceGrouped) {
            $content = @"

using Urasandesu.Prig.Framework;

namespace $(ConcatIfNonEmpty $namespaceGrouped.Key '.')Prig
{
    public class P$(& $ToClassNameFromType $declTypeGrouped.Key) : P$(& $ToBaseNameFromType $declTypeGrouped.Key) $(& $ToGenericParameterConstraintsFromType $declTypeGrouped.Key)
    {
"@ + $(foreach ($stub in $declTypeGrouped) {
@"

        public static class $(& $ToClassNameFromStub $stub) $(& $ToGenericParameterConstraintsFromStub $stub)
        {
            public static $(& $ToClassNameFromType $stub.IndirectionDelegate) Body
            {
                set
                {
                    var info = new IndirectionInfo();
                    info.AssemblyName = "$($AssemblyInfo.FullName)";
                    info.Token = TokenOf$($stub.Name);
                    var holder = LooseCrossDomainAccessor.GetOrRegister<IndirectionHolder<$(& $ToClassNameFromType $stub.IndirectionDelegate)>>();
                    holder.AddOrUpdate(info, value);
                }
            }
        }
"@}) + @"

    }
}
"@
            $result = 
                New-Object psobject | 
                    Add-Member NoteProperty 'Path' ([System.IO.Path]::Combine($WorkDirectory, "$(ConcatIfNonEmpty $dir '\')$($declTypeGrouped.Key.Name).cs")) -PassThru | 
                    Add-Member NoteProperty 'Content' $content -PassThru
            [Void]$results.Add($result)
        }
    }

    ,$results
}
