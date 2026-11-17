function [root,parent] = findRoot(parent,node)
% Find one component root and compress the path for later searches.
root = node;
while parent(root) ~= root
    root = parent(root);
end

while parent(node) ~= node
    next = parent(node);
    parent(node) = root;
    node = next;
end
end
