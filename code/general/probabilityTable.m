function p = probabilityTable(p, labels, fileName, maxColumnCharacters)

% probability table
%   produces a labeled (i) latex table in a text file (ii) csv file
%   and (iii) markdown table in textfile with pairwise probabilities in p

n = numel(labels);

% write .txt file with latex
fid = fopen(sprintf('tables/%s_probabilityTable.txt', fileName), 'w');
fprintf(fid, '\\begin{table}\n');
fprintf(fid, '\\begin{center}\n');
fprintf(fid, '\\resizebox{\\textwidth}{!}{\n');
fprintf(fid, '\\begin{tabular}{%s}\n', ['r' repmat('c', [1, n])]);
fprintf(fid, '\\toprule\n');
str = '';
for idx = 1:n
   str = sprintf('%s & %s', str, labels{idx}(1:min(length(labels{idx}), maxColumnCharacters)));
end
fprintf(fid, sprintf('%s \\\\\\\\ \n', str));
fprintf(fid, '\\hline\n');
for idx1 = 1:n
   str = labels{idx1};
   for idx2 = 1:n
      if idx1 == idx2
         str = sprintf('%s & --', str);
      else
         str = sprintf('%s & %1.2f', str, p(idx1, idx2));
      end
   end
   fprintf(fid, sprintf('%s \\\\\\\\ \n', str));
end
fprintf(fid, '\\bottomrule\n');
fprintf(fid, '\\end{tabular}}\n');
fprintf(fid, '\\end{center}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);

% write .csv file
fid = fopen(sprintf('tables/%s_probabilityTable.csv', fileName), 'w');
str = '';
for idx = 1:n
   str = sprintf('%s , %s', str, labels{idx}(1:min(length(labels{idx}), maxColumnCharacters)));
end
fprintf(fid, sprintf('%s \n', str));
for idx1 = 1:n
   str = labels{idx1};
   for idx2 = 1:n
      if idx1 == idx2
         str = sprintf('%s , ', str);
      else
         str = sprintf('%s , %1.2f', str, p(idx1, idx2));
      end
   end
   fprintf(fid, sprintf('%s\n', str));
end
fclose(fid);

% write markdown text file
fid = fopen(sprintf('tables/%s_probabilityTableMD.txt', fileName), 'w');
str = '| ';
for idx = 1:n
   str = sprintf('%s | %s', str, labels{idx}(1:min(length(labels{idx}), maxColumnCharacters)));
end
fprintf(fid, sprintf('%s | \n', str));
str = '| ----- |';
for idx = 1:n
   str = sprintf(' %s ----- |', str);
end
fprintf(fid, sprintf('%s \n', str));
for idx1 = 1:n
   str = ['| ' labels{idx1}];
   for idx2 = 1:n
      if idx1 == idx2
         str = sprintf('%s | ', str);
      else
         str = sprintf('%s | %1.2f ', str, p(idx1, idx2));
      end
   end
   fprintf(fid, sprintf('%s |\n', str));
end
fclose(fid);









