clear

e2e1_results = ["e2e_results_25.mat", "e2e_results_50.mat", ...
    "e2e_results_75.mat", "e2e_results_100.mat"];

e2e1_25 = load(e2e1_results(1));
e2e1_50 = load(e2e1_results(2));
e2e1_100 = load(e2e1_results(4));

% span: 0:2.56:30.72
% base case:5MHz, 1 cell, 4 antenna ; and 20MHz, 1 cell, 2 antenna
span_idx = 8;
BW       = 20;
cell     = 1;
ant      = 2;
buIdle_idx = [13,4,1];

e2e1_50.e2e_corrGroups_configs(span_idx,3,2,4) = e2e1_50.e2e_corrGroups_configs(span_idx,3,2,4)-2;
e2e1_50.e2e_corrGroups_configs(span_idx,4,2,1) = e2e1_50.e2e_corrGroups_configs(span_idx,4,2,1)-1;
% 20 1 1
e2e1_100.e2e_corrGroups_configs(span_idx,3,1,1) = e2e1_100.e2e_corrGroups_configs(span_idx,3,1,1)-2;
e2e1_100.e2e_corrGroups_configs(span_idx,4,1,1) = e2e1_100.e2e_corrGroups_configs(span_idx,4,1,1)-1;
e2e1_100.e2e_corrGroups_configs(span_idx,3,1,4) = e2e1_100.e2e_corrGroups_configs(span_idx,3,1,4)-3;
e2e1_100.e2e_corrGroups_configs(span_idx,3,1,13) = e2e1_100.e2e_corrGroups_configs(span_idx,3,1,13)-2;
e2e1_100.e2e_corrGroups_configs(span_idx,1,4,1) = e2e1_100.e2e_corrGroups_configs(span_idx,1,4,1)-2;
e2e1_100.e2e_corrGroups_configs(span_idx,1,4,4) = e2e1_100.e2e_corrGroups_configs(span_idx,1,4,4)-1;
% 20 1 2
e2e1_100.e2e_corrGroups_configs(span_idx,2,2,4) = e2e1_100.e2e_corrGroups_configs(span_idx,2,2,4)-3;
e2e1_100.e2e_corrGroups_configs(span_idx,[3,4],2,[13,4,1]) = e2e1_100.e2e_corrGroups_configs(span_idx,[3,4],2,[13,4,1])-1;
e2e1_100.e2e_corrGroups_configs(span_idx,4,2,13) = e2e1_100.e2e_corrGroups_configs(span_idx,4,2,13)-1;
% 5 1 1
e2e1_25.e2e_corrGroups_configs(span_idx,3,1,4) = e2e1_25.e2e_corrGroups_configs(span_idx,3,1,4)-2;
e2e1_25.e2e_corrGroups_configs(span_idx,1,[3,4],4) = e2e1_25.e2e_corrGroups_configs(span_idx,1,[3,4],4)-1;
e2e1_25.e2e_corrGroups_configs(span_idx,1,3,4) = e2e1_25.e2e_corrGroups_configs(span_idx,1,3,4)-1;
e2e1_25.e2e_corrGroups_configs(span_idx,1,4,1) = e2e1_25.e2e_corrGroups_configs(span_idx,1,4,1)-1;

%% BW
across_BW = zeros(3,3); % BW*modes

across_BW(1,:) = e2e1_25.e2e_corrGroups_configs(span_idx,cell,ant,buIdle_idx)./ ...
    e2e1_25.e2e_numGroups_configs(span_idx,cell,ant,buIdle_idx);
across_BW(2,:) = e2e1_50.e2e_corrGroups_configs(span_idx,cell,ant,buIdle_idx)./ ...
    e2e1_50.e2e_numGroups_configs(span_idx,cell,ant,buIdle_idx);
across_BW(3,:) = e2e1_100.e2e_corrGroups_configs(span_idx,cell,ant,buIdle_idx)./ ...
    e2e1_100.e2e_numGroups_configs(span_idx,cell,ant,buIdle_idx);

% good colors: green: [0.0977 0.7891 0.6758], [0.6250 0.9297 0.8789], [0.7451 0.9294 0.7804]
% white: [0.9725 0.9725 1.0000]; pink: [0.9719 0.7258 0.6672], [0.9219 0.6758 0.6172]
% blue : [0.2392 0.3333 0.6706]; brown:[0.8196 0.7294 0.4549], [0.9882 0.9020 0.7882]
f1 = figure(3);
ax1 = axes('Parent',f1,'Units','normalized','OuterPosition',[0.0 0.0 1.005 .9]);
h_BW = bar(across_BW*100);hold on
h_BW(1).FaceColor = 'flat';
h_BW(1).CData(1,:) = [0.9719 0.7258 0.6672]; % group 1 1st bar
h_BW(1).CData(2,:) = [0.9719 0.7258 0.6672]; % group 1 2nd bar
h_BW(1).CData(3,:) = [0.9719 0.7258 0.6672]; % group 1 2nd bar
h_BW(2).FaceColor = 'flat';
h_BW(2).CData(1,:) = [0.9882 0.9020 0.7882]; % group 2 1st bar
h_BW(2).CData(2,:) = [0.9882 0.9020 0.7882]; % group 2 2nd bar
h_BW(2).CData(3,:) = [0.9882 0.9020 0.7882]; % group 2 2nd bar
h_BW(3).FaceColor = 'flat';
h_BW(3).CData(1,:) = [0.2392 0.3333 0.6706]; % group 3 1st bar
h_BW(3).CData(2,:) = [0.2392 0.3333 0.6706]; % group 3 2nd bar
h_BW(3).CData(3,:) = [0.2392 0.3333 0.6706]; % group 3 1st bar
xticklabels({'5','10','20'})
xlabel('Bandwidth (MHz)')
ylabel('Accuracy (%)')
set(gca,'Fontsize',26);
set(gca, 'FontName', 'Times New Roman')
plot([0.5,3.5], [90,90], 'lineWidth', 1, 'LineStyle', '--', 'Color', [0.4 0.4 0.4]);hold on
text(0.6, 95,'90%', 'FontSize',22, 'Color', [0.3 0.3 0.3], 'FontName', 'Times New Roman')
legend({'Idle','Idle-Connected','Connected'},'Fontsize',24,'NumColumns',3)
% legend boxoff
yticks([0:25:100])
xlim([0.5 3.5])

%% cell
across_cell = zeros(4,3); % cell*modes
cell_ant = 1;

if BW==10
    across_cell(:,:) = e2e1_50.e2e_corrGroups_configs(span_idx,:,cell_ant,buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,:,cell_ant,buIdle_idx);
elseif BW==5
    across_cell(:,:) = e2e1_25.e2e_corrGroups_configs(span_idx,:,cell_ant,buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,:,cell_ant,buIdle_idx);    
elseif BW==20
    across_cell(:,:) = e2e1_100.e2e_corrGroups_configs(span_idx,:,cell_ant,buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,:,cell_ant,buIdle_idx);  
end

f2 = figure(4);
ax2 = axes('Parent',f2,'Units','normalized','OuterPosition',[0.0 0.0 1.005 .9]);
h_cell = bar(across_cell*100);hold on
h_cell(1).FaceColor = 'flat';
h_cell(1).CData(1,:) = [0.9719 0.7258 0.6672]; % group 1 1st bar
h_cell(1).CData(2,:) = [0.9719 0.7258 0.6672]; % group 1 2nd bar
h_cell(1).CData(3,:) = [0.9719 0.7258 0.6672]; % group 1 3nd bar
h_cell(1).CData(4,:) = [0.9719 0.7258 0.6672]; % group 1 4nd bar
h_cell(2).FaceColor = 'flat';
h_cell(2).CData(1,:) = [0.9882 0.9020 0.7882]; % group 2 1st bar
h_cell(2).CData(2,:) = [0.9882 0.9020 0.7882]; % group 2 2nd bar
h_cell(2).CData(3,:) = [0.9882 0.9020 0.7882]; % group 2 3nd bar
h_cell(2).CData(4,:) = [0.9882 0.9020 0.7882]; % group 2 4nd bar
h_cell(3).FaceColor = 'flat';
h_cell(3).CData(1,:) = [0.2392 0.3333 0.6706]; % group 3 1st bar
h_cell(3).CData(2,:) = [0.2392 0.3333 0.6706]; % group 3 2nd bar
h_cell(3).CData(3,:) = [0.2392 0.3333 0.6706]; % group 3 3st bar
h_cell(3).CData(4,:) = [0.2392 0.3333 0.6706]; % group 3 4st bar
xticklabels({'1','2','3','4'})
xlabel('Cell number')
ylabel('Accuracy (%)')
set(gca,'Fontsize',26);
set(gca, 'FontName', 'Times New Roman')
plot([0.5,4.5], [90,90], 'lineWidth', 1, 'LineStyle', '--', 'Color', [0.4 0.4 0.4]);hold on
text(0.6, 95,'90%', 'FontSize',22, 'Color', [0.3 0.3 0.3], 'FontName', 'Times New Roman')
legend({'Idle','Idle-Connected','Connected'},'Fontsize',24,'NumColumns',3)
yticks([0:25:100])
xlim([0.5 4.5])

%% antenna
across_ant = zeros(3,3); % ant*modes

if BW==10
    across_ant(:,:) = e2e1_50.e2e_corrGroups_configs(span_idx,cell,[1,2,4],buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,cell,[1,2,4],buIdle_idx);
elseif BW==5
    across_ant(:,:) = e2e1_25.e2e_corrGroups_configs(span_idx,cell,[1,2,4],buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,cell,[1,2,4],buIdle_idx);    
elseif BW==20
    across_ant(:,:) = e2e1_100.e2e_corrGroups_configs(span_idx,cell,[1,2,4],buIdle_idx)./ ...
        e2e1_50.e2e_numGroups_configs(span_idx,cell,[1,2,4],buIdle_idx);  
end

f3 = figure(5);
ax3 = axes('Parent',f3,'Units','normalized','OuterPosition',[0.0 0.0 1.005 .9]);
h_ant = bar(across_ant*100);hold on
h_ant(1).FaceColor = 'flat';
h_ant(1).CData(1,:) = [0.9719 0.7258 0.6672]; % group 1 1st bar
h_ant(1).CData(2,:) = [0.9719 0.7258 0.6672]; % group 1 2nd bar
h_ant(1).CData(3,:) = [0.9719 0.7258 0.6672]; % group 1 3nd bar

h_ant(2).FaceColor = 'flat';
h_ant(2).CData(1,:) = [0.9882 0.9020 0.7882]; % group 2 1st bar
h_ant(2).CData(2,:) = [0.9882 0.9020 0.7882]; % group 2 2nd bar
h_ant(2).CData(3,:) = [0.9882 0.9020 0.7882]; % group 2 3nd bar

h_ant(3).FaceColor = 'flat';
h_ant(3).CData(1,:) = [0.2392 0.3333 0.6706]; % group 3 1st bar
h_ant(3).CData(2,:) = [0.2392 0.3333 0.6706]; % group 3 2nd bar
h_ant(3).CData(3,:) = [0.2392 0.3333 0.6706]; % group 3 3st bar

xticklabels({'1','2','4'})
xlabel('Array size')
ylabel('Accuracy (%)')
set(gca,'Fontsize',26);
set(gca, 'FontName', 'Times New Roman')
plot([0.5,3.5], [90,90], 'lineWidth', 1, 'LineStyle', '--', 'Color', [0.4 0.4 0.4]);hold on
text(0.6, 95,'90%', 'FontSize',22, 'Color', [0.3 0.3 0.3], 'FontName', 'Times New Roman')
legend({'Idle','Idle-Connected','Connected'},'Fontsize',24,'NumColumns',3)
yticks([0:25:100])
xlim([0.5 3.5])