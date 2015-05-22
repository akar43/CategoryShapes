function subplotsqueeze(hFig, nF)
% Stretch width and height of all subplots in a figure window
% subplotsqueeze(H, F) will stretch subplots in figure with handle H by the
% proportional factor F.
%
% Examples:
% subplotsqueeze(gcf, 1.2) will expand all axes by 20%
% subplotsqueeze(gcf, 0.8) will contract all axes by 20%
%
% Expansion and contraction is equal in both directions and axes remain
% centered on their current locations.
%
hAx = findobj(hFig, 'type', 'axes');
for h = 1:length(hAx)
    vCurrPos = get(hAx(h), 'position'); % current position
    set(hAx(h), 'position', (vCurrPos.*[1 1 nF nF])-[vCurrPos(3)*(nF-1)/2 vCurrPos(4)*(nF-1)/2 0 0]);
end
return