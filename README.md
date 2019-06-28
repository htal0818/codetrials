# codetrials
java trial and error 


package main.com;

public class Main {
	public stack void main(String[] args) {
		IntStack intStack = new IntStack();
		
		if(intStack.isfull()) }
	intStack.ppush(2);
	intStack.push(4);
	intStack.ppush(6);
	intStack.push(9);
	
}
	
	System.out.println(intStack.pop());
	
	System.out.println(intStack.pop());
	}
	
	
	
}


public class IntStack {

	private int[] stack;
	private int top;
	private int size;
	public IntStack() {
		top = -1;
		size = 50;
		stack = new int [50];
		
	}
	
	public IntStack(int size) {
		top = -1;
		this.size = size;
		stack = new int [this.size];
		
		
		
	}
	public boolean push(int item) {
		if(isFull());
		top++;
		stack[top] = item;
		return true;
	} else {
		return false;
	
}
}
}


public int pop() {
	return stack[top--];
	
}

public boolean isEmpty() {
	return (top == -1);
	
}
	
	
	
	

	public boolean isFull() {
		return (top == stack.length - 1);
	}
	
	
	
	
}



package com.projectnew;

import java.util.*;



public class TestingOUt {
	
	static Scanner sc = new Scanner(System.in);
	
	public static void main(String[] args) {
		
		int[] a1 = new int[10];
		a1[0] = 1;
		Arrays.fill(a1,2);
		System.out.print(a1[0]);
				
		System.out.println(a1.length);
		String[] a2 = {"one" , "two"};
		int [] oneTo10 = IntStream.rangeClosed(1,10).toArray();
		
		for(int x: oneTo10) System.out.println(x);
		
		System.out.println(Arrays.binarySearch(oneTo10, 9));
		
		int a3[][] = new int[2][2];
		String[][] a4 = {{"00", "10"}, 
						 {"01", "11"}};
		
		System.out.print("Enter name : ");;
		if(sc.hasNextLine()) {
			String userName = sc.nextLine();
			System.out.println("Hello " + userName);
		
	
		}
		
		String jopName = 
				JOptionPane.showInputDialog("Enter Name");
			System.out.println("Hello " + jopName);
			
		
	}

}


package com.projectnew;

import java.util.Arrays;
import java.util.Scanner;

public class TestingOUt2 {

static Scanner sc = new Scanner(System.in);
	
	public static void main(String[] args) {
		
		int[] a1 = new int[10];
		a1[0] = 1;
		Arrays.fill(a1,2);
		System.out.print(a1[0]);
				
		System.out.println(a1.length);
		String[] a2 = {"one" , "two"};
		int [] oneTo10 = IntStream.rangeClosed(1,10).toArray();
		
		for(int x: oneTo10) System.out.println(x);
		
		System.out.println(Arrays.binarySearch(oneTo10, 9));
		
		int a3[][] = new int[2][2];
		String[][] a4 = {{"00", "10"}, 
						 {"01", "11"}};
		
		System.out.print("Enter name : ");;
		if(sc.hasNextLine()) {
			String userName = sc.nextLine();
			System.out.println("Hello " + userName);
		
	
		}
		
		String jopName = 
				JOptionPane.showInputDialog("Enter Name");
			System.out.println("Hello " + jopName);
			
	import javax.swing.J0ptionPane;
	
	
	int age = 12;
	if((age >= 5) && (age <= 6)) {
		System.out.println("Go to Kindergarten");
	} else if ((age >= 7) && (age <= 13))
		System.our.println("Go to Middle School");
	else if ((age >= 14) && (age <= 18))
		System.out.println("Go to High School")
	else { 
		System.out.println(Stay Home");
	}
	
	
	System.out.println("true || false = " + (true || false));
	System.out.println("!true = " + (!true));
	
	boolean canVote = (age >= 18) ? true : false;
	System.out.println("Can vote : " + canVote);
	
	String lang = "France";
	switch(lang) {
	case "Chile" : case "Cuba" : 
		System.out.println("Hola");
		break;
	case "France" : 
		System.out.println("Bounjour");
		break;
	case "Japan" : 
		System.out.println("Konichiwa");
		break;
		default: 
			System.out.println("Hello");
			
			
			
			for(int i = 0; i < 5; i ++) {
				System.out.println(i);
			}
			
			int wL = 0;
			while(wL < 20) {
				if(wL % 2 == 0) {
					System.out.println(wL);
					wL++;
					continue;
				}
				if(wL >= 10) {
					break;
				}
				wL++;
			}
			
			int secretNum = 7;
			int guess = 0;
			do {
				System.out.println("Guess : ");
				if(sc.hasNextInt()) {
					guess = sc.nextInt();
				}
			}while(secretNum != guess); 
			System.out.println("You guessed it");
			
			package com.trialtwonew;

public class trial2wo {

	static Scanner sc = new Scanner(System.in);
	
	public static int getSum(int x, int y) {
		return x + y;
	}
		public static void changeMe(int cnum) {
			int cNum = 10;
		
	}
		
	public static int getSum2(int ... nums) {
		int sum = 0;
		for(int x: nums) {
			sum += x;
		}
		return sum;
		
	}
	
	static int[] getNext2(int x) {
		int[] vals = new int [2];
		vals[0] = x + 1;
		vals[1] = x + 2;
		return vals;
}
	
	public static void main(String[] args) {
		
		System.out.println("5 + 4 =" + getSum(5,4));
		
		int cNum = 0;
		changeMe(cNum);
		System.out.println("cNum = " + cNum);
		
		System.out.println("Sum : " + getSum2(1,2,3,4));
		
		int[] multVA = getNext2(5);
		for(int x: multVA) System.out.println(x);
		
		List<Object> randlist = GetRandList();
		System.out.println(randlist)
		
	
		
		
		
		
	}

}

			
		
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
							
				}
			}
	
		
			
		
	}

}
}



