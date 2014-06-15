#!/usr/bin/env ruby
# encoding: UTF-8

# SEE: http://pcsupport.about.com/od/tipstricks/a/execfileext.htm
# NOTE: this is not compatible with GNU 'which' util for Windows
WINDOWS_EXECUTABLE_FILE_EXTENSIONS = "BAT,CMD,COM,CPL,EXE,GADGET,INF1,INS,INX,ISU,JOB,JSE,LNK,MSC,MSI,MSP,MST,PAF,PIF,PS1,REG,RGS,SCT,SHB,SHS,U3P,VB,VBE,VBS,VBSCRIPT,WS,WSF"

module CompGen
    def CompGen.get
        exes = []

        ENV['PATH'].split(';').uniq.each do |path|
            path.gsub!("\\", '/')

            Dir["#{path}/*.{#{WINDOWS_EXECUTABLE_FILE_EXTENSIONS}}"].each do |file|
                exes << File.basename(file, '.*')
            end
        end

        exes.sort.uniq
    end
end

if __FILE__ == $0
    puts CompGen.get
end
