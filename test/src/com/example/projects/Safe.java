package com.example.projects;

public class Safe {
	private int a;
	
	public Safe(int a) {
		this.a = a;
	}
	
	public int getA() {
		return a;
	}
	
	// This class is executable and outputs the first argument it is passed
	public static void main(String[] args) {
		String arg = args[0];
		System.out.println(arg);
	}
}