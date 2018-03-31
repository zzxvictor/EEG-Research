function varargout = mypatcher( varargin )
    %MYDIFF Matlab implementation of the unix patch utility (unified diffs only)
    %   This is a Matlab implementation of the unix patch utility, though
    %   not fully featured. It currently only works on unified diff text
    %   files, ie, the files created by "diff -u old new" and is not POSIX
    %   compliant.
    %
    % SYNTAX:
    %     MYPATCHER( file_to_be_patched, patch )
    %     patched_text = MYPATCHER( ... )
    %     [patched_text, info] = MYPATCHER( ... )
    %     MYPATCHER(..., output_file)
    %
    % DESCRIPTION:
    %     MYPATCHER( file_to_be_patched, patch ) takes a unified diff file
    %        specified by |patch| and applies it to |file_to_be_patched|.
    %        The resulting file is output to |file_to_be_patched.patched|
    %        as well as output to the screen. |file_to_be_patched| must be
    %        a text file, not binary. MYPATCHER does not check whether the
    %        surrounding text matches.
    %     patched_text = MYPATCHER( ... ) puts the changed text in
    %        |patched_text| instead of displaying and outputting to file
    %     [patched_text, info] = MYPATCHER( ... ) also includes some info
    %        about the patch file hunks and |file_to_be_patched|.
    %     MYPATCHER(..., output_file) uses |output_file| instead of
    %        |file_to_be_patched.patched| as the output destination.
    %
    % INPUTS:
    %     file_to_be_patched - Name of the file to be patched. Cannot be a
    %        binary file
    %     patch - Name of the patch file to apply. Must be a unified diff
    %        file.
    %     output_file - Name of the file to output to. Will be erased if it
    %        already exists.
    % OUTPUTS:
    %     patched_text - A string containing the result of applying the
    %        patch file to the input file.
    %     info - A struct containing the input file as a whole string and
    %        line-by-line in a struct and the hunks of the patch file in a
    %        different struct along with the hunk header information.
    % EXAMPLES:
    %     Given the files 'file.old' and 'file.new' we can find the updates
    %     using 
    %          |%>diff -u file.old file.new > file.patch|
    %     We can now run MYPATCHER to get a patched version of 'file.old'
    %     like so:
    %          |MYPATCHER('file.old','file.patch')|
    % SEE ALSO:
    %     <a href="matlab:web(
    %     'http://en.wikipedia.org/wiki/Diff/#Unified_format' )" >
    %     Wikipedia Unified Diff Article</a>
    %
    
    % Copyright & License: This code is CC-BY.
    %
    % Author:  02-May-2013, Michael Ryan, v1.0
    % Author: 2015, Benjamin Girault, v1.1
    
    in = parseInput(varargin{:});
    
    file.text = fileread(in.file);
    patch.text = fileread(in.patch);
    
    file.lines = regexp(file.text,'\r?\n','split');
    patch.header = regexp(patch.text,'^.*\r?\n.*\r?\n','match','dotexceptnewline');
    patch.text = strrep(patch.text,patch.header,'');
    patch.text = patch.text{1};
    checkNewline = regexp(patch.text,'\ No newline at end of file', 'once');
    if ~isempty(checkNewline)
        patch.text = patch.text(1:checkNewline);
        patch.newLine = ['Warning: no newline at end of file: ',in.file];
    end
    
    hunk_pattern = ['@@[ \t]*-(?<ol>\d+)(?<os>,\d+)?[ \t]+\+(?<nl>\d+)(?<ns>,\d+)?[ \t]*@@\r?\n',...
        '(?<hunk>([^@].*\r?\n)*)'...
        ];
    
    patch.hunks = regexp(patch.text,hunk_pattern,'names','dotexceptnewline');
    
    for ii=1:numel(patch.hunks)
        hunk = patch.hunks(ii);
        hunk.ol = str2double(hunk.ol);
        hunk.os = str2double(strrep(hunk.os,',',''));
        hunk.nl = str2double(hunk.nl);
        hunk.ns = str2double(strrep(hunk.ns,',',''));
        hunk.hunk = regexp(hunk.hunk,'\r?\n','split')';
        hunk.hunk = hunk.hunk(1:end-1);
        patch.hunks(ii) = hunk;
    end
    
    newtext=cell(0);
    lastline = 1;
    for ii=1:numel(patch.hunks)
        hunk = patch.hunks(ii);
        start = length(newtext);
        newtext(start+(1:hunk.ol-lastline)) = file.lines(lastline:(hunk.ol-1));
        delta = cellfun(@parseLine,hunk.hunk,'UniformOutput',false);
        inds = cell2mat(cellfun(@(x)isempty(x)||~isnan(x(1)),delta,'UniformOutput',false));
        if isempty(hunk.os)
            hunk.os = sum(~cell2mat(cellfun(@(x)strcmp(x(1),'+'),hunk.hunk)));
        end
        delta = delta(inds);
        start = length(newtext);
        newtext(start+(1:length(delta))) = delta;
        lastline = hunk.ol+hunk.os;
    end
    
    if lastline<length(file.lines)
        start = length(newtext);
        newtext(start+(1:length(file.lines)-lastline+1)) = file.lines(lastline:end);
    end
        
    newtext = cellfun(@(x)[x,sprintf('\n')],newtext(1:end),'UniformOutput',false);
    newtext = [newtext{:}];
    
    flag = ~(strcmp(file.text(end-1:end),'\r\n')||strcmp(file.text(end),'\n'));
    if flag
        newtext = newtext(1:end-1);
    end
    
    out.file=file;
    out.patch=patch;
    if nargout==0
        %disp(newtext);
        fid=fopen(in.output,'w');
        if fid>2
            fprintf(fid,strrep(strrep(newtext,'\','\\'),'%','%%'));
            fclose(fid);
        else
            warning('MYPATCHER:FILE_ERROR','Could not print to file: %s',ferror(fid));
        end
    elseif nargout==1
        varargout{1}=newtext;
    elseif nargout==2
        varargout{1}=newtext;
        varargout{2}=out;
    end
end

function outLine = parseLine(inLine)
    if isempty(regexp(inLine,'^-','once'))
        outLine = inLine(2:end);
    else
        outLine = nan;
    end
end

function in=parseInput(varargin)
    parser = inputParser;

    parser.addRequired('file',@(x)exist(x,'file'));
    parser.addRequired('patch',@(x)exist(x,'file'));
    parser.addOptional('output','',@(x)ischar(x));

    parser.parse(varargin{:});

    in.file = parser.Results.file;
    in.patch = parser.Results.patch;
    in.output = parser.Results.output;
    if isempty(in.output)
        [path, in.output, ext] = fileparts(in.file);  %#ok<ASGLU,NASGU>
        in.output = [in.output,'.patched'];
    end
end
