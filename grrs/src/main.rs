use histogram::Histogram;
use regex::Regex;
use std::collections::HashMap;
use std::fs::File;
use std::io::{self, prelude::*, BufReader};
use structopt::StructOpt;

/// Search for a pattern in a file and display the lines that contain it.
#[derive(StructOpt)]
struct Cli {
    /// The path to the file to read
    #[structopt(parse(from_os_str))]
    path: std::path::PathBuf,
}

struct User {
    start_time: i32,
    success_time: i32,
    end_time: i32,
}

fn print_gram(msg: &str, gram: Histogram) {
    assert_ne!(gram.entries(), 0, "It is not possible to print a histogram with no data");
    println!(
        "{}: p68: {}, p90: {}, p99: {}, p99.9: {}, p99.99: {}, max: {}",
        msg,
        gram.percentile(68.0).unwrap(),
        gram.percentile(90.0).unwrap(),
        gram.percentile(99.0).unwrap(),
        gram.percentile(99.9).unwrap(),
        gram.percentile(99.99).unwrap(),
        gram.maximum().unwrap(),
    );
}

fn main() -> io::Result<()> {
    let args = Cli::from_args();

    let file = File::open(&args.path).unwrap();
    let reader = BufReader::new(file);
    // let content = std::fs::read_to_string(&args.path).expect("could not read file");

    let mut users: HashMap<String, User> = HashMap::new();

    for line in reader.lines() {
        let re = Regex::new(r"(\d{10}) USER (\d+) (\w+)").unwrap();
        let line = line.unwrap();
        match re.captures(line.as_str()) {
            Some(caps) => {
                let this_time = caps.get(1).unwrap().as_str().parse::<i32>().unwrap();
                let user = users
                    .entry(caps.get(2).unwrap().as_str().to_string())
                    .or_insert(User {
                        start_time: 0,
                        success_time: 0,
                        end_time: 0,
                    });
                match caps.get(3).unwrap().as_str() {
                    "COMPLETED" => {
                        user.end_time = this_time;
                        ()
                    }
                    "SUCCESS" => {
                        user.success_time = this_time;
                        ()
                    }
                    "STARTED" => {
                        user.start_time = this_time;
                        ()
                    }
                    _ => (),
                }
            }
            None => (),
        }
    }

    let mut success_gram = Histogram::new();
    let mut complete_gram = Histogram::new();
    let mut diff_gram = Histogram::new();
    let mut total = 0;
    let mut succeeded = 0;
    println!("Building histogram...");
    for (index, times) in users.iter() {
        total += 1;
        if times.end_time == 0 || times.success_time == 0 {
            println!("User {} did not complete.", index.to_string());
        } else if times.start_time == 0 {
            println!("Something terrible happened to User {}", index.to_string());
        } else {
            succeeded += 1;
            success_gram.increment((times.success_time - times.start_time) as u64);
            complete_gram.increment((times.end_time - times.start_time) as u64);
            diff_gram.increment((times.end_time - times.success_time) as u64);
        }
    }
    println!("Histograms built");

    if succeeded != 0 {
      print_gram("First success", success_gram);
      print_gram("Last failure", complete_gram);
      print_gram("Propogation time: difference between first success and last failure", diff_gram);
    }

    println!(
        "{} of {} users successfully completed their tasks",
        succeeded.to_string(),
        total.to_string()
    );

    Ok(())
}
