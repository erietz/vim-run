

let mylist = [1,2,3,4,5, 'ethan', 3,2,4, 'ethan']

call filter(mylist, 'v:val !~ "ethan"')

echo mylist
